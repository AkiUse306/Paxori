using System.Net.Http.Json;

namespace PaxoriApp.Services;

public class OpenAiChatService : IChatService
{
    private readonly HttpClient _httpClient;

    public OpenAiChatService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public string Name => "ChatGPT";

    public async Task<ChatResponse> GetResponseAsync(ChatRequest request)
    {
        await Task.Delay(300);
        return new ChatResponse
        {
            Model = Name,
            Content = $"[ChatGPT] Paxori would describe the project as a secure cross-platform transfer app with a focus on speed, usability, and modular architecture. Prompt: {request.Prompt}",
            Success = true
        };
    }
}
