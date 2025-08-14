import argparse
import json
import os
import sys

from ai import openai, anthropic, gemini
from helpers import log, sanitize

def create_payload(diff, repo):
    system_instruction = f"""
    You are an expert programmer that can do review on critical issues on different type of files.
    You have access to to the whole contents of the changed files, file specific squashed diffs, and file specific relevant commits.
    The target audience is the developer that has made the changes and who is only interested in critical issues.
    The code you are reviewing has already been compiled successfully so there cannot be any syntax errors.
              
    Here are the diff logs of the changed files:
    {diff}
    """

    command = f"""
    Please ONLY comment on the following critical issues in the changed files:
    - Clear typos
    - Clear errors in logic
    - Comments not matching the code
              
    Base your analysis on the full file content and use the file diff as a guide to ONLY comment on the changed parts.
    Do not include the the diff parts in your output, rather include relevant lines from the full file content.
    ONLY comment on the critical issues and do not include any other issues. If there are no critical issues, tell the developer that there are no critical issues.
              
    Only base your answer on the available files.
    Always include the file name and small amount of surrounding lines to give context for the issue.
    Note that '{repo}/' is not written in the original logs, so you write that on your own when giving file structures.
    Be as brief as possible and avoid long explanations.
    Do not add any closing remarks or a summary.
              
    Use GitHub markdown syntax in your response. Do not wrap the response in ```markdown.
    """

    payload = {
        "system_instruction": system_instruction,
        "command": command
    }

    return payload

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument('--diff', required=True)
    p.add_argument('--provider', required=True)
    args = p.parse_args()

    repo = os.environ.get("GITHUB_REPOSITORY").split("/")[0]
    branch = os.environ.get("GITHUB_REF_NAME")
    actor = os.environ.get("GITHUB_ACTOR");

    log("Creating payload for code review generation...", "info") 
    request_payload = create_payload(sanitize(args.diff), repo)
    log("Completed creating payload for code review generation.", "info")

    log("Generating code review...", "info")

    response = None
    if args.provider == "openai":
        api_key = os.environ.get("OPENAI_API_KEY")
        response = openai.generate_text("gpt-5", request_payload["system_instruction"], request_payload["command"], "medium", api_key)
    elif args.provider == "anthropic":
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        response = anthropic.generate_text("claude-sonnet-4-20250514", request_payload["system_instruction"], request_payload["command"], api_key)
    elif args.provider == "gemini":
        api_key = os.environ.get("GEMINI_API_KEY")
        response = gemini.generate_text("gemini-2.5-pro-preview-06-05", request_payload["system_instruction"], request_payload["command"], api_key)
    else:
        log(f"Provider '{args.provider}' is currently not supported.", "error")
        sys.exit(1)

    log("Completed generating code review.", "info")

    if response["error"] is True:
        sys.exit(1)
    else:
        log("Adding code review to file", "info")

        payload = { "code_review": f"{response["message"]}" }
        with open("./.github/code_review.json", "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False)

        log("Code review added to file successfully.", "info")
        log("Code review generated.", "success")