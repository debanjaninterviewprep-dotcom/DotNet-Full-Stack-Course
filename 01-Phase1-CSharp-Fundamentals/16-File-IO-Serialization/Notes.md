# Topic 16: File I/O & Serialization

## File I/O Overview

File I/O (Input/Output) lets your program **read from** and **write to** files on disk. Serialization converts objects to a **storable format** (JSON, XML, binary) and back.

```
Your App ←→ File System
           ├── Text Files (.txt, .csv, .log)
           ├── JSON Files (.json)
           ├── XML Files (.xml)
           └── Binary Files (.dat, .bin)
```

---

## Working with Paths — System.IO.Path

Always use `Path` methods instead of string concatenation for cross-platform safety.

```csharp
// Combine paths safely
string folder = @"C:\Users\Debanjan\Documents";
string fileName = "tasks.json";
string fullPath = Path.Combine(folder, fileName);
// C:\Users\Debanjan\Documents\tasks.json

// Extract parts
Console.WriteLine(Path.GetFileName(fullPath));        // tasks.json
Console.WriteLine(Path.GetFileNameWithoutExtension(fullPath)); // tasks
Console.WriteLine(Path.GetExtension(fullPath));       // .json
Console.WriteLine(Path.GetDirectoryName(fullPath));   // C:\Users\Debanjan\Documents

// Special folders
string desktop = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
string tempFile = Path.GetTempFileName(); // Creates a unique temp file
string tempDir = Path.GetTempPath();       // System temp folder

// Current directory
string currentDir = Directory.GetCurrentDirectory();
```

---

## Directory Operations

```csharp
// Check if directory exists
if (Directory.Exists(@"C:\MyFolder"))
    Console.WriteLine("Folder exists!");

// Create directory (creates all missing parent folders too)
Directory.CreateDirectory(@"C:\MyFolder\SubFolder\Deep");

// List contents
string[] files = Directory.GetFiles(@"C:\MyFolder");            // Files only
string[] dirs = Directory.GetDirectories(@"C:\MyFolder");       // Subdirectories only
string[] allItems = Directory.GetFileSystemEntries(@"C:\MyFolder"); // Both

// Search with pattern
string[] csvFiles = Directory.GetFiles(@"C:\Data", "*.csv");
string[] allCsv = Directory.GetFiles(@"C:\Data", "*.csv", SearchOption.AllDirectories);

// Delete directory
Directory.Delete(@"C:\MyFolder", recursive: true); // true = delete contents too
```

---

## File Operations — Quick Methods

### File.WriteAllText / File.ReadAllText

```csharp
string filePath = "greeting.txt";

// Write (creates or overwrites)
File.WriteAllText(filePath, "Hello, Debanjan!\nWelcome to C#.");

// Read entire file as string
string content = File.ReadAllText(filePath);
Console.WriteLine(content);

// Append to existing file
File.AppendAllText(filePath, "\nThis line was appended.");
```

### File.WriteAllLines / File.ReadAllLines

```csharp
// Write array of strings (each becomes a line)
string[] lines = { "Line 1: Hello", "Line 2: World", "Line 3: C# is great" };
File.WriteAllLines("data.txt", lines);

// Read all lines into array
string[] readLines = File.ReadAllLines("data.txt");
foreach (string line in readLines)
    Console.WriteLine(line);

// Read all lines as IEnumerable (lazy — better for large files)
foreach (string line in File.ReadLines("data.txt"))
    Console.WriteLine(line);
```

### File.WriteAllBytes / File.ReadAllBytes

```csharp
// Write raw bytes
byte[] data = { 0x48, 0x65, 0x6C, 0x6C, 0x6F }; // "Hello" in ASCII
File.WriteAllBytes("data.bin", data);

// Read raw bytes
byte[] readData = File.ReadAllBytes("data.bin");
Console.WriteLine(System.Text.Encoding.ASCII.GetString(readData)); // Hello
```

### File Information & Checks

```csharp
// Check existence
if (File.Exists("data.txt"))
    Console.WriteLine("File exists!");

// File info
FileInfo info = new FileInfo("data.txt");
Console.WriteLine($"Size: {info.Length} bytes");
Console.WriteLine($"Created: {info.CreationTime}");
Console.WriteLine($"Modified: {info.LastWriteTime}");
Console.WriteLine($"Extension: {info.Extension}");
Console.WriteLine($"Full Path: {info.FullName}");

// Copy, Move, Delete
File.Copy("source.txt", "destination.txt", overwrite: true);
File.Move("old.txt", "new.txt");
File.Delete("unwanted.txt");
```

---

## StreamReader & StreamWriter — For Large Files

Quick methods (`ReadAllText`, etc.) load the ENTIRE file into memory. For large files, use **streams** to read/write incrementally.

### StreamWriter

```csharp
// Using statement ensures the file is properly closed
using (StreamWriter writer = new StreamWriter("log.txt"))
{
    writer.WriteLine("Log Entry 1");
    writer.WriteLine("Log Entry 2");
    writer.Write("No newline here");
}

// Modern C# — using declaration
using StreamWriter writer2 = new StreamWriter("log.txt", append: true);
writer2.WriteLine("Appended entry");

// With explicit encoding
using StreamWriter utf8Writer = new StreamWriter("data.txt", false, System.Text.Encoding.UTF8);
utf8Writer.WriteLine("UTF-8 encoded text");
```

### StreamReader

```csharp
// Read entire file
using StreamReader reader = new StreamReader("log.txt");
string allContent = reader.ReadToEnd();

// Read line by line (memory-efficient for large files)
using StreamReader lineReader = new StreamReader("largefile.txt");
string? line;
int lineNumber = 0;
while ((line = lineReader.ReadLine()) != null)
{
    lineNumber++;
    Console.WriteLine($"{lineNumber}: {line}");
}

// Read character by character
using StreamReader charReader = new StreamReader("data.txt");
while (!charReader.EndOfStream)
{
    char c = (char)charReader.Read();
    Console.Write(c);
}
```

---

## Async File Operations

For non-blocking I/O (especially in web apps), use async methods.

```csharp
// Async write
await File.WriteAllTextAsync("data.txt", "Hello async world!");

// Async read
string content = await File.ReadAllTextAsync("data.txt");

// Async read lines
string[] lines = await File.ReadAllLinesAsync("data.txt");

// Async with streams
using StreamWriter writer = new StreamWriter("async-log.txt");
await writer.WriteLineAsync("Async line 1");
await writer.WriteLineAsync("Async line 2");

using StreamReader reader = new StreamReader("async-log.txt");
string? line;
while ((line = await reader.ReadLineAsync()) != null)
{
    Console.WriteLine(line);
}
```

---

## JSON Serialization — System.Text.Json

JSON is the **most common** format for data exchange in modern apps.

### Basic Serialization (Object → JSON)

```csharp
using System.Text.Json;

public class Person
{
    public string Name { get; set; } = "";
    public int Age { get; set; }
    public string Email { get; set; } = "";
    public List<string> Skills { get; set; } = new();
}

Person person = new Person
{
    Name = "Debanjan",
    Age = 25,
    Email = "debanjan@example.com",
    Skills = new List<string> { "C#", "Angular", "SQL" }
};

// Serialize to JSON string
string json = JsonSerializer.Serialize(person);
Console.WriteLine(json);
// {"Name":"Debanjan","Age":25,"Email":"debanjan@example.com","Skills":["C#","Angular","SQL"]}

// Pretty print
var options = new JsonSerializerOptions { WriteIndented = true };
string prettyJson = JsonSerializer.Serialize(person, options);
Console.WriteLine(prettyJson);
// {
//   "Name": "Debanjan",
//   "Age": 25,
//   "Email": "debanjan@example.com",
//   "Skills": ["C#", "Angular", "SQL"]
// }
```

### Basic Deserialization (JSON → Object)

```csharp
string json = """
{
    "Name": "Debanjan",
    "Age": 25,
    "Email": "debanjan@example.com",
    "Skills": ["C#", "Angular", "SQL"]
}
""";

Person? person = JsonSerializer.Deserialize<Person>(json);
Console.WriteLine(person?.Name);   // Debanjan
Console.WriteLine(person?.Age);    // 25
```

### Customizing JSON Property Names

```csharp
using System.Text.Json.Serialization;

public class Product
{
    [JsonPropertyName("product_name")]
    public string Name { get; set; } = "";
    
    [JsonPropertyName("unit_price")]
    public decimal Price { get; set; }
    
    [JsonIgnore] // Excluded from JSON
    public string InternalCode { get; set; } = "";
    
    [JsonPropertyName("in_stock")]
    public bool IsAvailable { get; set; }
}

// With camelCase naming policy
var options = new JsonSerializerOptions
{
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    WriteIndented = true
};

string json = JsonSerializer.Serialize(new Product
{
    Name = "Laptop",
    Price = 999.99m,
    InternalCode = "SECRET",
    IsAvailable = true
}, options);
// {"product_name":"Laptop","unit_price":999.99,"in_stock":true}
// Note: InternalCode is NOT included (JsonIgnore)
```

### Serialization Options

```csharp
var options = new JsonSerializerOptions
{
    WriteIndented = true,                          // Pretty print
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase, // camelCase keys
    DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull, // Skip nulls
    PropertyNameCaseInsensitive = true,            // Case-insensitive deserialization
    Converters = { new JsonStringEnumConverter() } // Enums as strings
};
```

### Serialize/Deserialize Collections

```csharp
List<Person> people = new List<Person>
{
    new Person { Name = "Debanjan", Age = 25 },
    new Person { Name = "Alice", Age = 30 }
};

// Serialize list
string json = JsonSerializer.Serialize(people, new JsonSerializerOptions { WriteIndented = true });

// Deserialize list
List<Person>? loaded = JsonSerializer.Deserialize<List<Person>>(json);
```

### File-Based JSON Operations

```csharp
// Save to file
async Task SaveToJsonAsync<T>(string filePath, T data)
{
    var options = new JsonSerializerOptions { WriteIndented = true };
    string json = JsonSerializer.Serialize(data, options);
    await File.WriteAllTextAsync(filePath, json);
}

// Load from file
async Task<T?> LoadFromJsonAsync<T>(string filePath)
{
    if (!File.Exists(filePath))
        return default;
    
    string json = await File.ReadAllTextAsync(filePath);
    return JsonSerializer.Deserialize<T>(json);
}

// Usage
var tasks = new List<TaskItem>
{
    new TaskItem { Id = 1, Title = "Learn C#", IsComplete = true },
    new TaskItem { Id = 2, Title = "Build API", IsComplete = false }
};

await SaveToJsonAsync("tasks.json", tasks);
var loaded = await LoadFromJsonAsync<List<TaskItem>>("tasks.json");
```

---

## XML Serialization

XML is used in many enterprise systems and configurations.

```csharp
using System.Xml.Serialization;

public class Employee
{
    public string Name { get; set; } = "";
    public int Age { get; set; }
    public string Department { get; set; } = "";
}

// Serialize to XML
Employee emp = new Employee { Name = "Debanjan", Age = 25, Department = "Engineering" };
XmlSerializer serializer = new XmlSerializer(typeof(Employee));

using (StreamWriter writer = new StreamWriter("employee.xml"))
{
    serializer.Serialize(writer, emp);
}
// <?xml version="1.0" encoding="utf-8"?>
// <Employee>
//   <Name>Debanjan</Name>
//   <Age>25</Age>
//   <Department>Engineering</Department>
// </Employee>

// Deserialize from XML
using (StreamReader reader = new StreamReader("employee.xml"))
{
    Employee? loaded = (Employee?)serializer.Deserialize(reader);
    Console.WriteLine(loaded?.Name); // Debanjan
}
```

---

## CSV Reading & Writing

```csharp
// Write CSV
var employees = new List<(string Name, int Age, string Dept)>
{
    ("Debanjan", 25, "Engineering"),
    ("Alice", 30, "Marketing"),
    ("Bob", 28, "HR")
};

using StreamWriter writer = new StreamWriter("employees.csv");
writer.WriteLine("Name,Age,Department"); // Header
foreach (var emp in employees)
    writer.WriteLine($"{emp.Name},{emp.Age},{emp.Dept}");

// Read CSV
using StreamReader reader = new StreamReader("employees.csv");
string? header = reader.ReadLine(); // Skip header

string? line;
while ((line = reader.ReadLine()) != null)
{
    string[] parts = line.Split(',');
    Console.WriteLine($"Name: {parts[0]}, Age: {parts[1]}, Dept: {parts[2]}");
}
```

### Handling CSV Edge Cases

```csharp
// Fields with commas need quoting: "Smith, John",30,"New York, NY"
// Simple CSV parser (for learning — use CsvHelper library in production)
string[] ParseCsvLine(string line)
{
    List<string> fields = new List<string>();
    bool inQuotes = false;
    string current = "";
    
    foreach (char c in line)
    {
        if (c == '"')
            inQuotes = !inQuotes;
        else if (c == ',' && !inQuotes)
        {
            fields.Add(current.Trim());
            current = "";
        }
        else
            current += c;
    }
    fields.Add(current.Trim());
    return fields.ToArray();
}
```

---

## Working with File Streams (Advanced)

### FileStream — Low-Level Access

```csharp
// Write bytes
using FileStream fs = new FileStream("data.bin", FileMode.Create, FileAccess.Write);
byte[] data = System.Text.Encoding.UTF8.GetBytes("Hello binary world!");
await fs.WriteAsync(data);

// Read bytes
using FileStream readFs = new FileStream("data.bin", FileMode.Open, FileAccess.Read);
byte[] buffer = new byte[readFs.Length];
await readFs.ReadAsync(buffer);
string text = System.Text.Encoding.UTF8.GetString(buffer);
Console.WriteLine(text);
```

### FileMode Options

| FileMode | Description |
|---|---|
| `Create` | Creates new or overwrites existing |
| `CreateNew` | Creates new — throws if exists |
| `Open` | Opens existing — throws if not found |
| `OpenOrCreate` | Opens if exists, creates if not |
| `Append` | Opens for appending (write only) |
| `Truncate` | Opens and clears content |

---

## Practical: JSON-Based Data Store

A reusable class for persisting any data to JSON files:

```csharp
public class JsonDataStore<T> where T : new()
{
    private readonly string _filePath;
    private readonly JsonSerializerOptions _options;

    public JsonDataStore(string filePath)
    {
        _filePath = filePath;
        _options = new JsonSerializerOptions
        {
            WriteIndented = true,
            PropertyNameCaseInsensitive = true
        };
    }

    public async Task SaveAsync(T data)
    {
        string json = JsonSerializer.Serialize(data, _options);
        await File.WriteAllTextAsync(_filePath, json);
    }

    public async Task<T> LoadAsync()
    {
        if (!File.Exists(_filePath))
            return new T();

        string json = await File.ReadAllTextAsync(_filePath);
        return JsonSerializer.Deserialize<T>(json, _options) ?? new T();
    }
}

// Usage
var store = new JsonDataStore<List<TaskItem>>("tasks.json");

var tasks = await store.LoadAsync();
tasks.Add(new TaskItem { Id = 1, Title = "New Task" });
await store.SaveAsync(tasks);
```

---

## Key Takeaways

| Concept | Summary |
|---|---|
| `File.ReadAllText/WriteAllText` | Quick read/write for small files |
| `StreamReader/StreamWriter` | Line-by-line for large files |
| Async file methods | Non-blocking I/O with `Async` variants |
| `Path.Combine` | Safe path construction |
| `System.Text.Json` | Modern, fast JSON serialization |
| `JsonSerializerOptions` | Customize naming, formatting, null handling |
| `[JsonPropertyName]` | Control JSON key names |
| `[JsonIgnore]` | Exclude properties from JSON |
| `XmlSerializer` | XML serialization for enterprise systems |
| `FileStream` | Low-level byte read/write |
| `using` statement | Always use for streams to ensure cleanup |

---

*Next Topic: Generics →*
