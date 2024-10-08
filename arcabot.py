import os
import time

# Set the time zone to your local time zone, e.g., 'Asia/Kuala_Lumpur'
os.environ['TZ'] = 'Asia/Kuala_Lumpur'
if hasattr(time, 'tzset'):
    time.tzset()

import nest_asyncio
nest_asyncio.apply()

import asyncio
import sys
import subprocess
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, CallbackContext

# Use your actual bot token here
BOT_TOKEN = '7881544736:AnuDX0Gy1O1YP4C5jkdjmhqSszGU8eDMCL4'

# The chat ID to send the final message to
CHAT_ID = -1009088361845

def execute_command(command):
    try:
        # Run the command on OpenWrt and capture the output
        result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode == 0:
            return result.stdout  # Return command output
        else:
            return f"Error: {result.stderr}"  # Return error message
    except Exception as e:
        return str(e)

async def start(update: Update, context: CallbackContext) -> None:
    await update.message.reply_text('Hello! I am your bot.')

async def balas_telegram(update: Update, context: CallbackContext) -> None:
    message_text = update.message.text.lower()

    name = update.message.from_user.first_name
    username = update.message.from_user.username
    if username:
        username_display = f"@{username}"
    else:
        username_display = "No Username"

    if message_text.startswith('.'):
        command = message_text[len('.'):].strip()  # Extract the command after !command!
        output = execute_command(command)  # Execute the extracted command
        await context.bot.send_message(chat_id=CHAT_ID, text=output)  # Send the result to the Telegram group

async def main() -> None:
    application = Application.builder().token(BOT_TOKEN).build()

    # Add handlers for commands and messages
    application.add_handler(CommandHandler("start", start))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, balas_telegram))

    # Start polling for updates
    await application.run_polling()

if __name__ == '__main__':
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(main())
    except KeyboardInterrupt:
        print("Bot stopped.")
    finally:
        if not loop.is_closed():
            loop.close()
