namespace PaxoriApp.Services;

public interface IChatService
{
    string Name { get; }
    Task<ChatResponse> GetResponseAsync(ChatRequest request);
}
