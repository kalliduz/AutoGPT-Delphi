# AutoGPT-Delphi
This is an experiment to create a fully autonomous GPT-instance to solve arbitrary Tasks. Its functionality is similar to AutoGPT(Python), BabyAGI or Jarvis
## Requirements
  - Delphi OpenAI API implementation from https://github.com/HemulGM/DelphiOpenAI
  - OpenAI API key (https://platform.openai.com/account/api-keys)
  - Google Custom Search API key & SearchEngine-ID (https://console.cloud.google.com/apis/credentials)
  - libssl/libeay for IndyHttp with SSL (https://github.com/IndySockets/OpenSSL-Binaries/)

AutoGPT-Delphi uses GPT-4 by default, and will utilize GPT3.5-turbo for summarizations, so watch your costs in OpenAI. You can set the main agent to be 3.5 as well,
but at the current point, the consistency is not really what you'd want.
## Plans for the future
  - Improve the system prompt to make even GPT 3.5 understand it
  - rewrite the agent syntax to be easier parseable
  - introduce more agents (Txt2Img, Compiling, FileListing)
  - introduce asynchronous calls to utilize to full power of parallel agents
## Implementation

To create a simple application, you just need to create the AgentManager and run it.
```delphi
AutoGPT:= TAutoGPTManager.Create('AGENT_TASK','YOUR_OPEN_AI_API_KEY','AGENT_WORKSPACE_DIRECTORY','GOOGLE_CUSTOM_SEARCH_API_KEY','GOOGLE_CUSTOM_SEARCH_ENGINE_ID',UserCallback);
AutoGPT.RunOneStep;
ShowMessage(AutoGPT.MemoryToString);

```

 
