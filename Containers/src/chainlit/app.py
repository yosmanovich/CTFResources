import os
from dotenv import load_dotenv, dotenv_values 
import chainlit as cl
from openai import AsyncOpenAI

load_dotenv() 
# Configure the async OpenAI client
client = AsyncOpenAI(api_key=os.getenv("API_KEY", "nothing"), base_url=os.getenv("BASE_URL", "http://ollama:11434/v1"))

settings = {
    "model": os.getenv("MODEL", "TinyLlama:latest"),
    "temperature": 0.7,
    "max_tokens": 500,
}

@cl.on_chat_start
def start_chat():
    # Initialize message history
    cl.user_session.set("message_history", [{"role": "system", "content": "You are a helpful chatbot."}])

@cl.on_message
async def main(message: cl.Message):
    # Retrieve the message history from the session
    message_history = cl.user_session.get("message_history")
    message_history.append({"role": "user", "content": message.content})

    # Create an initial empty message to send back to the user
    msg = cl.Message(content="")
    await msg.send()

    # Use streaming to handle partial responses
    stream = await client.chat.completions.create(messages=message_history, stream=True, **settings)

    async for part in stream:
        if token := part.choices[0].delta.content or "":
            await msg.stream_token(token)

    # Append the assistant's last response to the history
    message_history.append({"role": "assistant", "content": msg.content})
    cl.user_session.set("message_history", message_history)

    # Update the message after streaming completion
    await msg.update()