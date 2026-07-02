using System.Net.Http.Json;

namespace PaxoriApp.Services;

public class ClaudeChatService : IChatService
{
    private readonly HttpClient _httpClient;

    public ClaudeChatService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public string Name => "Claude";

    public async Task<ChatResponse> GetResponseAsync(ChatRequest request)
    {
        await Task.Delay(300);
        return new ChatResponse
        {
            Model = Name,
            Content = $"[Claude] Paxori appears as a lightweight, reliable transfer engine with cross-platform UI and secure file delivery. Prompt: {request.Prompt}",
            Success = true
        };
    }
}
