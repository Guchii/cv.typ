-- Requires dkjson (install via: luarocks install dkjson)
local json = require("dkjson")
local io = require("io")

-- Get inputs from environment variables
local cv_file_path = assert(os.getenv("CV_FILE_PATH"), "Missing env var: CV_FILE_PATH")
local job_description = assert(os.getenv("JOB_DESCRIPTION"), "Missing env var: JOB_DESCRIPTION")
-- Hardcode model name for now due to act input issues
local model_name = "google/gemini-flash-1.5" -- Or use 'google/gemma-2-9b-it'

-- Removed debug print

-- Read CV file content
local cv_file = assert(io.open(cv_file_path, "r"), "Cannot open CV file: " .. cv_file_path)
local cv_content = assert(cv_file:read("*a"), "Cannot read CV file")
cv_file:close()

-- Define prompt components
local prompt_instructions = [[
You are a resume tailoring assistant. Your goal is to help keep the resume concise, ideally fitting on one page.
Analyze the provided resume YAML content and the job description below.
Modify the 'highlights' in the 'work' and 'projects' sections to best match the requirements and keywords found in the job description.
*   Rewrite highlights to be concise and impactful. Start each highlight with a strong action verb.
*   Focus on quantifiable results or specific achievements where possible.
*   Keep each highlight point brief, ideally one line.
*   Prioritize highlights most relevant to the job description. Remove or shorten less relevant ones if necessary for brevity.
You may also subtly reorder skills within categories in the 'skills' section if it emphasizes relevance to the job description.
Ensure your output is ONLY the complete, valid YAML content conforming to the original structure. Include ALL original sections and data, even if unmodified.
Do not add any commentary, explanations, markdown formatting, or anything outside the pure YAML structure.
The entire output must start with '# yaml-language-server: ...' and end with the last line of the YAML data.
Base Resume YAML:
]]

local job_desc_header = [[

Job Description:
]]

-- Combine into the full prompt content
local full_prompt_content = table.concat({
  prompt_instructions,
  cv_content,
  job_desc_header,
  job_description
}, "\n")

-- Construct the payload structure
local payload = {
  model = model_name,
  messages = {
    { role = "user", content = full_prompt_content }
  }
}

-- Encode payload to JSON and print to stdout
-- Use compact=true for single-line output suitable for curl -d
local json_string, err = json.encode(payload, { indent = false, compact = true })
if not json_string then
  io.stderr:write("JSON encoding error: ", err, "\n")
  os.exit(1)
end

print(json_string)
