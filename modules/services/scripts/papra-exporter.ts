import { parseArgs } from "node:util";
import { join, parse } from "node:path";
import { mkdir, exists } from "node:fs/promises";
import { ofetch } from "ofetch";

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
  console.error("Usage: bun run script.ts --org <org_id> --folder <download_path>");
  console.error("Note: PAPRA_API_KEY_PATH must still be set in your environment.");
  process.exit(1);
}

let apiKey: string;
try {
  const secretFile = Bun.file(secretFilePath);
  apiKey = (await secretFile.text()).trim();
} catch (error: any) {
  console.error(`Failed to read secret at ${secretFilePath}: ${error.message}`);
  process.exit(1);
}

async function getUniquePath(folder: string, fileName: string, suffix: string = "") {
  const safeName = fileName.replaceAll("/", "-");
  const { name, ext } = parse(safeName);
  const actualExt = suffix ? `${suffix}` : ext;

  let filePath = join(folder, `${name}${actualExt}`);
  if (!(await exists(filePath))) return filePath;

  let counter = 1;
  while (await exists(join(folder, `${name}-${counter}${actualExt}`))) {
    counter++;
  }

  return join(folder, `${name}-${counter}${actualExt}`);
}

async function listAllDocuments() {
  const apiClient = ofetch.create({
    headers: { "Authorization": `Bearer ${apiKey}` },
    baseURL: baseUrl
  });

  let allDocs: any[] = [];
  let pageIndex = 0;
  let hasMore = true;

  while (hasMore) {
    console.log(`Scanning page ${pageIndex + 1}...`);
    const response = await apiClient(`/api/organizations/${organizationId}/documents`, {
      method: "GET",
      query: { pageIndex, pageSize: 100 }
    });

    allDocs = [...allDocs, ...response.documents];
    if (allDocs.length >= response.documentsCount || response.documents.length === 0) {
      hasMore = false;
    } else {
      pageIndex++;
    }
  }
  return allDocs;
}

async function downloadDocument(documentId: string) {
  const apiClient = ofetch.create({
    headers: { "Authorization": `Bearer ${apiKey}` },
    baseURL: baseUrl
  });

  return await apiClient(`/api/organizations/${organizationId}/documents/${documentId}/file`, {
    method: "GET",
    responseType: "arrayBuffer"
  });
}

async function main() {
  try {
    const documents = await listAllDocuments();
    console.log(`Found ${documents.length} documents. Starting download...`);

    if (documents.length > 0) {
      await mkdir(downloadFolder, { recursive: true });

      for (let i = 0; i < documents.length; i++) {
        const doc = documents[i];
        try {
          const fileBuffer = await downloadDocument(doc.id);
          const fileSavedPath = await getUniquePath(downloadFolder, doc.name);
          await Bun.write(fileSavedPath, fileBuffer);

          const metaSavedPath = await getUniquePath(downloadFolder, doc.name, ".json");
          await Bun.write(metaSavedPath, JSON.stringify(doc, null, 2));

          console.log(`[${i + 1}/${documents.length}] Saved document: ${doc.name}`);
        } catch (err: any) {
          console.error(`Failed to download ${doc.name}: ${err.message}`);
        }
      }
      console.log(`\nAll data saved in ${downloadFolder}.`);
    }
  } catch (e: any) {
    console.error("Critical Error:", e.message);
  }
}

main();