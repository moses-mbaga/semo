import json
import time
import requests

from helpers import log

def send_request(system_instruction, command, reasoning_effort : str | None, api_key, model):
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
            endpoint = f"https://api.openai.com/v1/chat/completions"
            headers = { 
                "Content-Type": "application/json",
                "Authorization": f"Bearer {api_key}"
            }

            payload = {
                "model": model,
                "max_completion_tokens": 4000,
                "temperature": 0.7,
                "response_format": { "type": "text" },
                "messages": [
                    {
                        "role": "system",
                        "content": [
                            {
                                "type": "text",
                                "text": system_instruction
                            }
                        ]
                    },
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "text",
                                "text": command
                            }
                        ]
                    }
                ]
            }

            if reasoning_effort:
                payload["reasoning_effort"] = reasoning_effort
                payload.pop("temperature") # Not supported if reasoning effort is provided

            response = requests.post(
                endpoint,
                headers=headers,
                json=payload,
                timeout=300 # 5 minutes
            )

            response.raise_for_status()
            response_data = response.json()

            try:
                message = response_data['choices'][0]['message']['content']
                input_tokens = response_data['usage']['prompt_tokens']
                cached_tokens = response_data['usage']['prompt_tokens_details']['cached_tokens']
                output_tokens = response_data['usage']['completion_tokens']

                if message:
                    log(f"Model: {model}", "info")
                    if reasoning_effort:
                        log(f"Reasoning effort: {reasoning_effort}", "info")
                    log(f"Input tokens: {input_tokens}", "info")
                    log(f"Cached tokens: {cached_tokens}", "info")
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

def generate_text(model, system_instruction, command, reasoning_effort : str | None, api_key):
    return send_request(system_instruction, command, reasoning_effort, api_key, model)