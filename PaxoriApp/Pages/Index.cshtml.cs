using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Http;
using System.IO;

namespace PaxoriApp.Pages;

public class IndexModel : PageModel
{
    private const string UploadFolder = "wwwroot/uploads";

    [BindProperty]
    public List<IFormFile>? Files { get; set; }

    [BindProperty]
    public string SelectedDevice { get; set; } = "Ari's MacBook";

    public List<string> Devices { get; } = new()
    {
        "Ari's MacBook",
        "Linux Workstation",
        "Windows Surface"
    };

    public string StatusMessage { get; set; } = string.Empty;

    public List<FileItem> UploadedFiles { get; set; } = new();

    public void OnGet()
    {
        LoadUploadedFiles();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        LoadUploadedFiles();

        if (Files == null || !Files.Any())
        {
            StatusMessage = "Please select at least one file to transfer.";
            return Page();
        }

        var uploadPath = Path.Combine(Directory.GetCurrentDirectory(), UploadFolder);
        Directory.CreateDirectory(uploadPath);

        foreach (var file in Files)
        {
            var safeName = Path.GetFileName(file.FileName);
            var targetName = $"{DateTime.UtcNow:yyyyMMddHHmmssfff}_{safeName}";
            var targetPath = Path.Combine(uploadPath, targetName);

            await using var stream = System.IO.File.Create(targetPath);
            await file.CopyToAsync(stream);
        }

        StatusMessage = $"Transferred {Files.Count} file{(Files.Count > 1 ? "s" : "")} to {SelectedDevice}.";
        LoadUploadedFiles();
        return Page();
    }

    private void LoadUploadedFiles()
    {
        UploadedFiles.Clear();
        var uploadPath = Path.Combine(Directory.GetCurrentDirectory(), UploadFolder);

        if (!Directory.Exists(uploadPath))
        {
            return;
        }

        foreach (var filePath in Directory.GetFiles(uploadPath).OrderByDescending(System.IO.File.GetCreationTimeUtc))
        {
            var fileInfo = new FileInfo(filePath);
            UploadedFiles.Add(new FileItem
            {
                Name = fileInfo.Name,
                Size = fileInfo.Length,
                Url = $"/uploads/{Uri.EscapeDataString(fileInfo.Name)}"
            });
        }
    }

    public class FileItem
    {
        public required string Name { get; set; }
        public long Size { get; set; }
        public required string Url { get; set; }
    }
}
