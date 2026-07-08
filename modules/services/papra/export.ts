import { parseArgs } from "node:util";
import { join, parse } from "node:path";
import { mkdir } from "node:fs/promises";
import { ofetch } from "ofetch";

// configuration & cli parsing
const { values } = parseArgs({
  options: {
    org: { type: "string", short: "o" },
    folder: { type: "string", short: "f" },
  },
  strict: true,
});

const secretFilePath = Bun.env.PAPRA_API_KEY_PATH;
const organizationId = values.org;
const downloadFolder = values.folder;
const baseUrl = "http://127.0.0.1:1221";

if (!secretFilePath || !organizationId || !downloadFolder) {
  console.error("Error: Missing required arguments or environment variables.");
  console.error(
    "Usage: bun run script.ts --org <org_id> --folder <download_path>",
  );
  process.exit(1);
}

// read api key
let apiKey: string;
try {
  apiKey = (await Bun.file(secretFilePath).text()).trim();
} catch (error) {
  console.error(
    `Failed to read secret at ${secretFilePath}: ${(error as Error).message}`,
  );
  process.exit(1);
}

// initialize api client
const api = ofetch.create({
  baseURL: baseUrl,
  headers: { Authorization: `Bearer ${apiKey}` },
});

interface DocumentItem {
  id: string;
  name: string;
  [key: string]: any;
}

interface DocResponse {
  documents: DocumentItem[];
  documentsCount: number;
}

async function getUniquePath(
  folder: string,
  fileName: string,
  suffix = "",
): Promise<string> {
  const safeName = fileName.replaceAll("/", "-");
  const { name, ext } = parse(safeName);
  const actualExt = suffix || ext;

  let filePath = join(folder, `${name}${actualExt}`);
  if (!(await Bun.file(filePath).exists())) return filePath;

  let counter = 1;
  while (
    await Bun.file(join(folder, `${name}-${counter}${actualExt}`)).exists()
  ) {
    counter++;
  }
  return join(folder, `${name}-${counter}${actualExt}`);
}

async function listAllDocuments(): Promise<DocumentItem[]> {
  const allDocs: DocumentItem[] = [];
  let pageIndex = 0;
  let hasMore = true;

  while (hasMore) {
    console.log(`Scanning page ${pageIndex + 1}...`);
    const response = await api<DocResponse>(
      `/api/organizations/${organizationId}/documents`,
      {
        query: { pageIndex, pageSize: 100 },
      },
    );

    allDocs.push(...response.documents);

    // stop if we hit total count or get an empty page
    if (
      allDocs.length >= response.documentsCount ||
      response.documents.length === 0
    ) {
      hasMore = false;
    } else {
      pageIndex++;
    }
  }
  return allDocs;
}

async function downloadDocument(documentId: string): Promise<ArrayBuffer> {
  return api(
    `/api/organizations/${organizationId}/documents/${documentId}/file`,
    {
      responseType: "arrayBuffer",
    },
  );
}

// main orchestrator
async function main() {
  try {
    const documents = await listAllDocuments();
    if (documents.length === 0) {
      console.log("ℹNo documents found to download.");
      return;
    }

    console.log(`Found ${documents.length} documents. Starting download...`);
    await mkdir(downloadFolder, { recursive: true });

    for (let i = 0; i < documents.length; i++) {
      const doc = documents[i];
      const progress = `[${i + 1}/${documents.length}]`;

      try {
        const fileBuffer = await downloadDocument(doc.id);

        // save the document asset
        const fileSavedPath = await getUniquePath(downloadFolder, doc.name);
        await Bun.write(fileSavedPath, fileBuffer);

        // save the accompanying metadata
        const metaSavedPath = await getUniquePath(
          downloadFolder,
          doc.name,
          ".json",
        );
        await Bun.write(metaSavedPath, JSON.stringify(doc, null, 2));

        console.log(`${progress} Saved: ${doc.name}`);
      } catch (err) {
        console.error(
          `${progress} Failed to download ${doc.name}: ${(err as Error).message}`,
        );
      }
    }

    console.log(`\nAll available data saved in: ${downloadFolder}`);
  } catch (e) {
    console.error("Critical Error:", (e as Error).message);
  }
}

main();
