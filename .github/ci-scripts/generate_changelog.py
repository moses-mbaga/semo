import argparse
import json
import os
import sys

from ai import openai, anthropic, gemini
from helpers import log, sanitize

def create_payload(commit_info, diff, repo):
    system_instruction = f"""
    You are an expert programmer that can analyze what kind of high-level changes have been made in a codebase and create a changelog.
    You have access to the commits with their messages and changes (git diff log).
    The target audience is a project manager that needs to know high-level changes in the project.
    
    Here are all the changed files with their diffs and associated commits (git diff log):
    {commit_info}
    {diff}
    """

    command = f"""
    Please analyze the changes and create a changelog with a high-level description of the changes.
    Categorize the changes by the committer name.
    Then categorize the changes by using the folder structure, with '{repo}' as the root folder, for example '{repo}/lib', '{repo}/.github', etc. Do not include the file name in the category.
    Note that '{repo}/' is not written in the original diff log, so you write that on your own when giving file structures.
    Do not mention similar changes. Group the changes by the committer name and then by the folder structure.
    Under each category list the changes either as new features, bug fixes, or refactorings (in that order), for example:
    
    *John Doe*
    
    *{repo}/Folder Name*
    
    - [New feature] Added a new feature that does something.
    - [New feature] Added another new feature that does something else.
    - [Bug fix] Fixed a bug that caused something to not work.
    - [Refactoring] Refactored some code to make it more readable.
    
    *{repo}/AnotherFolderName*
    
    - [New feature] Added a new feature that does something.
    
    *Jane Doe*
    
    *{repo}/FolderName*
    
    - [Bug fix] Fixed a bug that caused something to not work.
    
    Keep each change description a single line and do not make it overly long.
    
    Use GitHub markdown syntax in your response. Do not wrap the response in ```markdown.
    """

    payload = {
        "system_instruction": system_instruction,
        "command": command
    }

    return payload

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument('--commit-info', required=True)
    p.add_argument('--diff', required=True)
    p.add_argument('--provider', required=True)
    args = p.parse_args()

    repo = os.environ.get("GITHUB_REPOSITORY").split("/")[0]
    branch = os.environ.get("GITHUB_REF_NAME")

    log("Creating payload for changelog generation...", "info") 
    request_payload = create_payload(sanitize(args.commit_info), sanitize(args.diff), repo)
    log("Completed creating payload for changelog generation.", "info")

    log("Generating changelog...", "info")

    response = None
    if args.provider == "openai":
        api_key = os.environ.get("OPENAI_API_KEY")
        response = openai.generate_text("gpt-5-mini", request_payload["system_instruction"], request_payload["command"], "minimal", api_key)
    elif args.provider == "anthropic":
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        response = anthropic.generate_text("claude-sonnet-4-20250514", request_payload["system_instruction"], request_payload["command"], api_key)
    elif args.provider == "gemini":
        api_key = os.environ.get("GEMINI_API_KEY")
        response = gemini.generate_text("gemini-2.5-pro-preview-06-05", request_payload["system_instruction"], request_payload["command"], api_key)
    else:
        log(f"Provider '{args.provider}' is currently not supported.", "error")
        sys.exit(1)

    log("Completed generating changelog.", "info")

    if response["error"] is True:
        sys.exit(1)
    else:
        log("Adding changelog to file", "info")

        payload = { "changelog": f"{response["message"]}" }
        with open("./.github/changelog.json", "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False)

        log("Changelog added to file successfully.", "info")
        log("Changelog generated.", "success")