import argparse
import json
import os
import sys

from ai import openai, anthropic, gemini, github_models
from helpers import log, sanitize

def create_payload(logs, repo):
    system_instruction = f"""
    You are an expert programmer that can analyze the reason(s) why a given software build has failed in a GitHub Actions workflow.
    You have access to the workflow source and the logs of the build steps.
    The target audience is an expert software developer that needs help to understand why the build has failed.
              
    Here are the build logs:
    {logs}
    """

    command = f"""
    Please analyze the given build step log files and give explanation why the build failed with following sections:
    - Full error message
    - Analysis of the error
    - Possible solution
              
    Do not add any other sections.
    In the 'Full error message' section put error message(s) inside a code block.
    In the 'Analysis of the error' section, explain the error(s) in clear language.
    In the 'Possible solutions' section, give one possible solution to each error.
              
    Only base your answer on the available log file information.
    Note that '{repo}/' is not written in the original logs, so you write that on your own when giving file structures.
    Do not invent any failure reasons that are not supported by the log files.
    If the log files do not contain enough information to determine the failure reason, please state that.
    Be as brief as possible and avoid long explanations.
    Do not add any closing remarks.
              
    Use GitHub markdown syntax in your response. Do not wrap the response in ```markdown.
    """

    payload = {
        "system_instruction": system_instruction,
        "command": command
    }

    return payload

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument('--logs', required=True)
    p.add_argument('--slack-id', required=False, default="")
    p.add_argument('--provider', required=True)
    args = p.parse_args()

    repo = os.environ.get("GITHUB_REPOSITORY").split("/")[0]
    branch = os.environ.get("GITHUB_REF_NAME")

    log("Creating payload for error analysis generation...", "info") 
    request_payload = create_payload(sanitize(args.logs), repo)
    log("Completed creating payload for error analysis generation.", "info")

    log("Generating error analysis...", "info")
    
    response = None
    if args.provider == "openai":
        api_key = os.environ.get("OPENAI_API_KEY")
        response = openai.generate_text("gpt-5", request_payload["system_instruction"], request_payload["command"], api_key)
    elif args.provider == "anthropic":
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        response = anthropic.generate_text("claude-sonnet-4-20250514", request_payload["system_instruction"], request_payload["command"], api_key)
    elif args.provider == "gemini":
        api_key = os.environ.get("GEMINI_API_KEY")
        response = gemini.generate_text("gemini-2.5-pro-preview-06-05", request_payload["system_instruction"], request_payload["command"], api_key)
    elif args.provider == "github_models":
        api_key = os.environ.get("GITHUB_MODELS_API_KEY")
        response = github_models.generate_text("openai/gpt-5", request_payload["system_instruction"], request_payload["command"], api_key)
    else:
        log(f"Provider '{args.provider}' is currently not supported.", "error")
        sys.exit(1)

    log("Completed generating error analysis.", "info")

    if response["error"] is True:
        sys.exit(1)
    else:
        log("Adding error analysis to file", "info")

        payload = { "error_analysis": f"{response["message"]}" }
        with open("./.github/error_analysis.json", "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False)

        log("Error analysis added to file successfully.", "info")

        log("Error analysis generated.", "success")
