namespace PaxoriApp.Services;

public class ChatRequest
{
    public string Prompt { get; set; } = string.Empty;
}

public class ChatResponse
{
    public string Model { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public bool Success { get; set; }
    public string? Error { get; set; }
}
