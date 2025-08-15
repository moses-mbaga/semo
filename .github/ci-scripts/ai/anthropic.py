import json
import time
import requests

from helpers import log

def send_request(system_instruction, command, enable_thinking, api_key, model):
    max_retries = 3
    wait_time = 5  # Seconds

    retry_count = 0
    response_data = {}

    while retry_count < max_retries:
        if retry_count > 0:
            log(f"Generating response with {model}...", "info")
        elif retry_count >= 1:
            log(f"Attempt {retry_count + 1} of {max_retries} to generate response with {model}...", "info")

        try:
            endpoint = "https://api.anthropic.com/v1/messages"
            headers = { 
                "Content-Type": "application/json",
                "x-api-key": api_key,
                "anthropic-version": "2023-06-01"
            }

            payload = {
                "model": model,
                "max_tokens": 4000,
                "temperature": 0.7,
                "system": system_instruction,
                "messages": [
                    {
                        "role": "user",
                        "content": command
                    }
                ]
            }

            if enable_thinking:
                payload["temperature"] = 1
                payload["thinking"] = {
                    "type": "enabled",
                    "budget_tokens": 3999,
                }

            response = requests.post(
                endpoint,
                headers=headers,
                json=payload,
                timeout=300  # 5 minutes
            )

            response.raise_for_status()
            response_data = response.json()

            try:
                message = ""

                if enable_thinking:
                    message = response_data['content'][1]['text']
                else:
                    message = response_data['content'][0]['text']

                input_tokens = response_data['usage']['input_tokens']
                output_tokens = response_data['usage']['output_tokens']

                if message:
                    log(f"Model: {model}", "info")
                    log(f"Input tokens: {input_tokens}", "info")
                    log(f"Output tokens: {output_tokens}", "info")
                    log(f"\n{message}")

                    return {
                        "error": False,
                        "message": message
                    }
                else:
                    log(f"Received empty message from API.", "error")
            except (KeyError, IndexError) as e:
                log(f"Failed to parse API response: {e}", "error")
                log(f"Response content: {json.dumps(response_data, indent=2)}", "error")

        except requests.exceptions.RequestException as e:
            log(f"Request failed: {e}", "error")

            if hasattr(e, 'response') and e.response:
                try:
                    error_details = e.response.json()
                    log(f"{json.dumps(error_details, indent=2)}", "error")
                except:
                    log(f"{e.response.text}", "error")
            
            log(f"{json.dumps(response_data, indent=2)}", "error")

        retry_count += 1
        if retry_count < max_retries:
            log(f"Waiting {wait_time} seconds before retry...", "info")
            time.sleep(wait_time)

    log(f"Failed to get valid response after {max_retries} retries.", "error")
    return { "error": True }

def generate_text(model, system_instruction, command, enable_thinking=False, api_key=None):
    return send_request(system_instruction, command, enable_thinking, api_key, model)