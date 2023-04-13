# AutoGPT-Delphi
This is an experiment to create a fully autonomous GPT-instance to solve arbitrary Tasks. Its functionality is similar to Auto-GPT(https://github.com/Torantulino/Auto-GPT), BabyAGI(https://github.com/yoheinakajima/babyagi) or Jarvis(https://github.com/microsoft/JARVIS).

⚠ Since the program can potentially execute harmful operations, it's recommended to run it inside a VM ⚠

## Requirements ✓
  - Delphi OpenAI API implementation from https://github.com/HemulGM/DelphiOpenAI
  - OpenAI API key (https://platform.openai.com/account/api-keys)
  - Google Custom Search API key & SearchEngine-ID (https://console.cloud.google.com/apis/credentials)
  - libssl/libeay for IndyHttp with SSL (https://github.com/IndySockets/OpenSSL-Binaries/)
## Currently available agents 🤖
  - USER          - prompts the user with a message and returns the output
  - WRITE_FILE    - writes a file into the workspace
  - READ_FILE     - reads a file from the workspace
  - BROWSE_SITE   - opens an URL and summarizes the content
  - SEARCH_GOOGLE - searches on google for a specific term 
  - WRITE_MEMORY  - keeps things in mind over the whole session (normally older thoughts will get lost)
  - GPT_TASK      - spawns a ChatGPT subinstance to execute a specific task
  - LIST_FILES    - returns the list of all files in the workspace
  - RUN_CMD       - executes an arbitrary command with cmd /c

AutoGPT-Delphi uses GPT-4 by default, and will utilize GPT3.5-turbo for summarizations, so watch your costs in OpenAI. You can set the main agent to be 3.5 as well,
but at the current point, the consistency is not really what you'd want.
## Plans for the future 🔮
  - Improve the system prompt to make even GPT 3.5 understand it
  - rewrite the agent syntax to be easier parseable
  - introduce more agents (Txt2Img, Compiling)
  - introduce asynchronous calls to utilize to full power of parallel agents
## Configuration ⚙
You need to specifiy your API-Keys in AutoGPT.ini

## Contact
If you have any questions or would like to contribute, feel free to contact via 
  - 📧 EMail: kalliduz.dev@gmail.com
  - 🗨 Discord: https://discordapp.com/users/kalliduz#7834
 
