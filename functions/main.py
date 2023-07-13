from firebase_functions import config, https_fn
import openai

# This line sets the API key for the OpenAI library.
openai.api_key = "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"

# This decorator registers the function as an HTTP-triggered function.


@https_fn.on_request
def get_openai_completion(req: https_fn.Request) -> https_fn.Response:
    # Get the 'prompt' parameter from the HTTP request.
    prompt = req.args.get('prompt')

    # If no prompt was provided, return an error.
    if prompt is None:
        return https_fn.Response("No prompt provided", status=400)

    # Call the OpenAI API to generate a text completion.
    completion = openai.Completion.create(
        engine="text-davinci-002",
        prompt=prompt,
        max_tokens=100
    )

    # Return the generated text as the HTTP response.
    return https_fn.Response(completion.choices[0].text.strip())
