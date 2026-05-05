# n8n-pdflatex

```
docker run -it --rm --name n8n-pdflatex-container -p 5678:5678 -e GENERIC_TIMEZONE="America/Halifax" -e TZ="America/Halifax" -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true -e N8N_RUNNERS_ENABLED=true -e N8N_EXECUTE_COMMAND_ENABLED=true -e NODES_EXCLUDE="[]" -v n8n_data:/home/node/.n8n -v C:/n8n-files:/home/node/.n8n-files n8n-pdflatex
```

# AI Resume and Cover Letter Generator with n8n, Ollama, and LaTeX

This project is an automated job application assistant built with n8n, Ollama, and LaTeX. It generates tailored cover letters and resumes from a pasted job description, resume LaTeX, and optional user notes.

The workflow uses a local Ollama model to create structured JSON suggestions, merges the generated content into LaTeX, compiles it with pdflatex, and returns downloadable PDF files through n8n forms.

---

## Features

- Generate a tailored cover letter PDF
- Generate a tailored resume PDF
- Download saved editable `.tex` files
- Use local Ollama models through `http://host.docker.internal:11434/api/chat`
- Keep generated output structured using JSON
- Compile LaTeX files with `pdflatex`
- Save generated files and change logs locally
- Add relevant bold keywords automatically
- Comment out weaker resume bullets instead of deleting them
- Support resume and cover letter workflows in one n8n project

---

## Workflow Overview

The project contains three main flows:

1. Cover Letter Generator
2. Resume PDF Generator
3. Download Saved TEX File

---

## 1. Cover Letter Generator

### Flow

```text
Form Trigger
↓
Build Ollama Request
↓
HTTP Request1
↓
Merge Body Into LaTeX
↓
Execute Command
↓
Read/Write Files from Disk
↓
Form
```

### What it does

This flow accepts company name, role title, job description, resume LaTeX, custom prompt, and extra notes.

It generates a short, human-sounding cover letter body, inserts it into a LaTeX template, compiles it, and returns a PDF.

### Main nodes

- Form Trigger
- Build Ollama Request
- HTTP Request1
- Merge Body Into LaTeX
- Execute Command
- Read/Write Files from Disk
- Form

---

## 2. Resume PDF Generator

### Flow

```text
Resume
↓
Code in JavaScript
↓
HTTP Request
↓
Merge Resume Suggestions
↓
Execute Command1
↓
Read/Write Files from Disk1
↓
Form1
```

### What it does

This flow accepts company name, role title, resume LaTeX, job description, and extra notes.

The workflow extracts experience and project sections from the resume, scores them against the job description, selects the most relevant sections, asks Ollama for targeted edits, applies those edits to the LaTeX resume, and compiles the final PDF.

### Main nodes

- Resume
- Code in JavaScript
- HTTP Request
- Merge Resume Suggestions
- Execute Command1
- Read/Write Files from Disk1
- Form1

---

## 3. Download Saved TEX File

### Flow

```text
Download TEX
↓
Build TEX Search Info
↓
Find TEX File1
↓
Clean TEX Path
↓
Read/Write Files from Disk2
↓
Form2
```

### What it does

This flow lets you download the saved editable `.tex` file for either a generated resume or a generated cover letter.

It searches local n8n file folders and returns the matching `.tex` file.

### Main nodes

- Download TEX
- Build TEX Search Info
- Find TEX File1
- Clean TEX Path
- Read/Write Files from Disk2
- Form2

---

## Tech Stack

- n8n for workflow automation
- Ollama for local LLM generation
- Gemma 3 model through Ollama
- JavaScript Code nodes for parsing, validation, scoring, and LaTeX merging
- LaTeX and pdflatex for PDF generation
- Local file storage for generated `.tex`, `.pdf`, and change log files
- n8n Form Trigger nodes for user input and file download

---

## Requirements

Before running this workflow, make sure you have:

- n8n installed and running
- Ollama installed and running locally
- `gemma3:latest` pulled locally
- LaTeX installed with `pdflatex`
- File system access enabled for n8n
- If using Docker, `host.docker.internal` must resolve correctly from the n8n container

Install the Ollama model:

```bash
ollama pull gemma3:latest
```

---

## Ollama API Endpoint

The workflow sends requests to:

```text
http://host.docker.internal:11434/api/chat
```

The HTTP Request nodes should send the full request body using:

```text
={{ $json.ollama_body }}
```

or:

```text
={{$json.ollama_body}}
```

Do not hardcode the model name inside the HTTP Request node. The model should come from the Code node through `ollama_body`.

---

## Main Input Fields

### Cover Letter Form

| Field | Description |
|---|---|
| LaTeX Template | Base cover letter template |
| Job Description | Job posting text |
| Custom Prompt | User style rules |
| Company Name | Target company |
| Role Title | Target role |
| Resume Latex | Resume content used as source facts |
| Extra Notes | Optional extra user instructions |

### Resume Form

| Field | Description |
|---|---|
| Company Name | Target company |
| Role Title | Target role |
| Resume LaTeX | Full LaTeX resume |
| Job Description | Job posting text |
| Extra Notes | Optional extra instructions |

---

## How the Resume Generator Works

The resume flow performs these steps:

1. Reads the submitted LaTeX resume.
2. Extracts `Experience` and `Projects` sections.
3. Extracts headings and bullet points from each section.
4. Scores each section against the job description.
5. Selects the most relevant sections.
6. Sends a controlled JSON prompt to Ollama.
7. Receives suggested resume edits.
8. Comments out weaker old bullets.
9. Adds new tailored bullets.
10. Bolds relevant keywords in newly added bullets.
11. Writes the updated `.tex` file.
12. Compiles the resume PDF using `pdflatex`.
13. Returns the PDF through the n8n form response.

The merge logic also stores a change log showing which edits succeeded or failed.

---

## How the Cover Letter Generator Works

The cover letter flow performs these steps:

1. Reads the job description, resume LaTeX, company name, role title, and custom prompt.
2. Converts the resume LaTeX into a shorter plain-text resume summary.
3. Sends a structured prompt to Ollama.
4. Expects JSON with `body`, `bold_keywords`, and `summary`.
5. Cleans the generated paragraphs.
6. Removes greetings, signatures, and corporate filler if the model adds them.
7. Escapes LaTeX-sensitive characters.
8. Applies bold keywords.
9. Inserts the body into a cover letter LaTeX template.
10. Compiles the final PDF.
11. Returns the downloadable file.

---

## Output Files

Generated files are saved under:

```text
/home/node/.n8n-files/
```

Example generated names:

```text
resume_company_role.pdf
resume_company_role.tex
resume_company_role_changes.json

cover_letter_company_role.pdf
cover_letter_company_role.tex
cover_letter_company_role_changes.json
```

The change log records:

- Summary
- Sections processed
- Successful edits
- Failed edits
- Applied suggestions
- Bold keywords used

---

## Important Notes

### Keep JSON output strict

The workflow expects Ollama to return valid JSON. The prompts tell the model to return only one JSON object with no markdown, no explanations, and nothing before or after the JSON.

This helps prevent the model from returning extra text or repeated output.

### Resume edits are conservative

The workflow does not directly delete old resume bullets. It comments them out so changes are reversible and easy to inspect.

Example:

```latex
% REMOVED (Less relevant to this role)
% \item Old resume bullet here.
```

### LaTeX compilation

Both resume and cover letter flows compile the `.tex` file twice using:

```bash
pdflatex -interaction=nonstopmode -halt-on-error file.tex
pdflatex -interaction=nonstopmode -halt-on-error file.tex
```

This helps resolve references and ensures the final PDF is generated correctly.

---

## Common Issues

### Ollama keeps generating after the JSON

Reduce `num_predict`, shorten the prompt, or reduce the number of sections being processed.

### HTTP Request uses the wrong model

Check that the HTTP Request body uses:

```text
={{ $json.ollama_body }}
```

Do not hardcode the model in the HTTP Request node.

### Resume PDF does not compile

Check the `Execute Command1` logs. Common causes include:

- Unescaped `%`
- Unescaped `&`
- Broken LaTeX commands
- Missing `pdflatex`
- Unsupported package in the runtime

### TEX file cannot be found

Use the Download TEX flow and make sure the company name and role title match the generated file slug.

---

## Recommended Model Settings

For cover letters:

```js
options: {
  temperature: 0.15,
  num_predict: 650,
  top_p: 0.75,
  repeat_penalty: 1.2,
  num_ctx: 8192
}
```

For resume tailoring:

```js
options: {
  temperature: 0.12,
  num_predict: 2000,
  top_p: 0.7,
  repeat_penalty: 1.22,
  num_ctx: 8192
}
```

---

## Suggested Repository Structure

```text
.
├── README.md
├── workflows/
│   └── cover-letter-resume.json
├── examples/
│   ├── sample-resume.tex
│   └── sample-job-description.txt
└── docs/
    └── troubleshooting.md
```

---

## Usage

1. Import the workflow JSON into n8n.
2. Make sure Ollama is running.
3. Make sure `gemma3:latest` is available locally.
4. Open the cover letter or resume form URL.
5. Paste the required inputs.
6. Submit the form.
7. Download the generated PDF.
8. Use the Download TEX flow if you want the editable LaTeX file.

---

## Security and Privacy

This workflow is designed to run locally. Resume content, job descriptions, generated files, and change logs stay inside your n8n/Ollama environment unless you deploy it externally.

Do not expose the form webhook publicly unless you add authentication, rate limiting, and file cleanup.

---

## Suggested Repository Names

- `ai-latex-resume-cover-letter-generator`
- `n8n-ai-resume-generator`
- `ollama-latex-job-application-assistant`

---

## License

This project is for personal automation and job application workflow use. Add your preferred license before publishing publicly.
