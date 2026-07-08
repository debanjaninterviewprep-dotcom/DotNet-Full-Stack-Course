# Topic 16: File I/O and Serialization — Interview Questions

---

## Q1. What is the difference between `File`, `FileInfo`, `Directory`, and `DirectoryInfo`?
**Answer:**
| Class | Type | Use |
|---|---|---|
| `File` | Static | One-shot file operations (read, write, copy, delete) — no object overhead |
| `FileInfo` | Instance | Multiple operations on the same file — caches attributes |
| `Directory` | Static | One-shot directory operations |
| `DirectoryInfo` | Instance | Multiple operations on the same directory |

```csharp
// Static — good for one-off operations
File.WriteAllText("log.txt", "Hello");
bool exists = File.Exists("log.txt");

// Instance — good when you need properties like Length, LastWriteTime
var fi = new FileInfo("log.txt");
Console.WriteLine(fi.Length);
Console.WriteLine(fi.LastWriteTime);
fi.CopyTo("backup.txt");
```

---

## Q2. What is a `Stream` and what are the common stream types?
**Answer:**
A `Stream` is an abstract representation of a **sequence of bytes**. It decouples producers and consumers from storage/transport details.

| Stream class | Source/Destination |
|---|---|
| `FileStream` | File on disk |
| `MemoryStream` | In-memory byte array |
| `NetworkStream` | TCP socket |
| `GZipStream` | Compressed data (decorator) |
| `CryptoStream` | Encrypted data (decorator) |
| `BufferedStream` | Adds buffering to another stream (decorator) |

Common operations: `Read`, `Write`, `Seek`, `Flush`, `Close`. Always use `using` to ensure disposal.

```csharp
using var fs = new FileStream("data.bin", FileMode.Create);
using var writer = new BinaryWriter(fs);
writer.Write(42);
writer.Write("Hello");
```

---

## Q3. What is the difference between `StreamReader`/`StreamWriter` and `BinaryReader`/`BinaryWriter`?
**Answer:**
- `StreamReader`/`StreamWriter` — read/write **text** (characters, lines). Handle character encoding (UTF-8 by default).
- `BinaryReader`/`BinaryWriter` — read/write **primitive types in binary format** (int, double, string with length prefix, etc.).

```csharp
// Text
using var sw = new StreamWriter("output.txt");
sw.WriteLine("Hello, World!");

using var sr = new StreamReader("output.txt");
string line = sr.ReadLine();

// Binary
using var bw = new BinaryWriter(File.Create("data.bin"));
bw.Write(3.14);
bw.Write(42);

using var br = new BinaryReader(File.OpenRead("data.bin"));
double pi = br.ReadDouble(); // 3.14
int n = br.ReadInt32();      // 42
```

---

## Q4. What is JSON serialization and how does `System.Text.Json` work?
**Answer:**
JSON serialization converts a .NET object to a JSON string; deserialization converts JSON back to an object.

```csharp
using System.Text.Json;

var person = new Person { Name = "Debanjan", Age = 25 };

// Serialize to JSON string
string json = JsonSerializer.Serialize(person);
// {"Name":"Debanjan","Age":25}

// Deserialize from JSON string
Person deserialized = JsonSerializer.Deserialize<Person>(json);

// With options
var options = new JsonSerializerOptions
{
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase, // camelCase output
    WriteIndented = true
};
string prettyJson = JsonSerializer.Serialize(person, options);
```

---

## Q5. What is the difference between `System.Text.Json` and `Newtonsoft.Json`?
**Answer:**
| | `System.Text.Json` | `Newtonsoft.Json` |
|---|---|---|
| **Included in** | .NET Core 3+ (built-in) | NuGet package |
| **Performance** | Faster, lower allocation | Slower |
| **Features** | Strict, fewer edge cases | More features, flexible |
| **`JsonProperty` attribute** | `[JsonPropertyName("name")]` | `[JsonProperty("name")]` |
| **Null handling** | Strict | More lenient |
| **Polymorphism** | Limited (needs `[JsonDerivedType]`) | Easier with `TypeNameHandling` |

Use `System.Text.Json` for new projects (default in ASP.NET Core). Use `Newtonsoft.Json` when you need advanced features or backward compatibility.

---

## Q6. What are the common file read/write methods on the `File` class?
**Answer:**
```csharp
// Write
File.WriteAllText("file.txt", "Hello");               // text, overwrites
File.AppendAllText("file.txt", "\nWorld");             // text, appends
File.WriteAllLines("file.txt", new[] {"Line1","Line2"}); // line by line
File.WriteAllBytes("file.bin", new byte[] {1,2,3});    // binary

// Read
string all = File.ReadAllText("file.txt");
string[] lines = File.ReadAllLines("file.txt");
byte[] bytes = File.ReadAllBytes("file.bin");

// Async versions (preferred for large files)
string all = await File.ReadAllTextAsync("file.txt");
await File.WriteAllTextAsync("file.txt", content);
```

---

## Q7. What is the `Path` class and why is it important?
**Answer:**
`Path` provides static methods for **cross-platform path manipulation** without string concatenation:

```csharp
// DON'T do this — breaks on Linux
string path = "C:\\Users\\Debanjan\\docs" + "\\" + "file.txt";

// DO this — uses OS separator automatically
string path = Path.Combine("C:\\Users\\Debanjan\\docs", "file.txt");

Path.GetFileName("C:\\Users\\file.txt")    // "file.txt"
Path.GetExtension("report.pdf")            // ".pdf"
Path.GetFileNameWithoutExtension("a.pdf")  // "a"
Path.GetDirectoryName("C:\\Users\\file.txt") // "C:\\Users"
Path.GetTempPath()                          // temp directory
Path.GetRandomFileName()                    // random file name
```

---

## Q8. What is `IDisposable` and why is it critical for file I/O?
**Answer:**
`IDisposable` allows objects to release resources (file handles, network connections) **deterministically** via `Dispose()`. File streams hold OS-level file handles — if not disposed, the file may remain locked.

```csharp
// Always use using to ensure Dispose() is called
using (var fs = new FileStream("file.txt", FileMode.Open))
{
    // work with fs
} // fs.Dispose() called — file handle released

// C# 8+ using declaration
using var reader = new StreamReader("file.txt");
// reader.Dispose() at end of scope
```

Without `using`, the file handle is released only when the GC runs the finalizer — which is non-deterministic and may never happen on low-memory systems.

---

## Q9. What are the common serialization attributes for `System.Text.Json`?
**Answer:**
```csharp
using System.Text.Json.Serialization;

class Product
{
    [JsonPropertyName("product_name")]   // custom JSON key
    public string Name { get; set; }

    [JsonIgnore]                          // exclude from JSON
    public string InternalCode { get; set; }

    [JsonInclude]                         // include public field
    public decimal Price;

    [JsonConverter(typeof(JsonStringEnumConverter))] // enum as string
    public ProductStatus Status { get; set; }

    [JsonPropertyOrder(1)]               // control output order
    public int Id { get; set; }
}
```

---

## Q10. How do you handle large files without loading everything into memory?
**Answer:**
Use **streaming** instead of `File.ReadAllText` / `File.ReadAllBytes`:

```csharp
// Read line by line — O(1) memory regardless of file size
await foreach (string line in File.ReadLinesAsync("huge.csv"))
{
    ProcessLine(line);
}

// Stream copy — avoid loading entire file
using var input = File.OpenRead("source.bin");
using var output = File.Create("dest.bin");
await input.CopyToAsync(output);

// Stream JSON deserialization (System.Text.Json)
using var stream = File.OpenRead("large.json");
var data = await JsonSerializer.DeserializeAsync<MyData>(stream);
```

For very large files, also consider `Span<byte>` / `Memory<byte>` with `PipeReader` (System.IO.Pipelines) for zero-copy processing.

---

## Q11. What is XML serialization with `XmlSerializer`?
**Answer:**
`XmlSerializer` converts objects to/from XML. It only serializes **public properties and fields** and requires a **parameterless constructor**:

```csharp
[XmlRoot("Person")]
public class Person
{
    [XmlElement("full_name")]   public string Name { get; set; } = "";
    [XmlAttribute("age")]       public int Age { get; set; }
    [XmlIgnore]                 public string Internal { get; set; } = "";
}

var person = new Person { Name = "Debanjan", Age = 25 };

// Serialize to XML
var serializer = new XmlSerializer(typeof(Person));
using var sw = new StringWriter();
serializer.Serialize(sw, person);
string xml = sw.ToString(); // <Person age="25"><full_name>Debanjan</full_name></Person>

// Deserialize from XML
using var sr = new StringReader(xml);
Person? restored = (Person?)serializer.Deserialize(sr);
```

`XmlSerializer` generates and JIT-compiles serialization code on first use — cache the instance for performance.

---

## Q12. What is `FileSystemWatcher` and how do you use it?
**Answer:**
`FileSystemWatcher` monitors a directory for file system changes and raises events:

```csharp
using var watcher = new FileSystemWatcher(@"C:\Logs")
{
    NotifyFilter = NotifyFilters.FileName | NotifyFilters.LastWrite,
    Filter = "*.log",
    IncludeSubdirectories = true,
    EnableRaisingEvents = true
};

watcher.Created += (s, e) => Console.WriteLine($"Created: {e.FullPath}");
watcher.Changed += (s, e) => Console.WriteLine($"Changed: {e.FullPath}");
watcher.Deleted += (s, e) => Console.WriteLine($"Deleted: {e.FullPath}");
watcher.Renamed += (s, e) => Console.WriteLine($"Renamed: {e.OldFullPath} → {e.FullPath}");
watcher.Error   += (s, e) => Console.WriteLine($"Error: {e.GetException().Message}");

Console.ReadLine(); // keep alive
```

**Caution:** Events fire on a background thread — use `Invoke` to marshal to UI thread in desktop apps. Multiple rapid changes can overflow the internal buffer; handle the `Error` event.

---

## Q13. What is `MemoryMappedFile` and when is it useful?
**Answer:**
`MemoryMappedFile` maps a file (or shared memory) directly into the process's address space, enabling random-access reads/writes without explicit buffering:

```csharp
// Write using memory-mapped file
using var mmf = MemoryMappedFile.CreateFromFile("data.bin", FileMode.Create,
    mapName: null, capacity: 1024 * 1024);
using var accessor = mmf.CreateViewAccessor();
accessor.Write(0, 42);         // write int at offset 0
accessor.Write(4, 3.14);       // write double at offset 4

// Read it back
int n = accessor.ReadInt32(0); // 42

// Shared memory between processes (named)
using var shared = MemoryMappedFile.CreateOrOpen("SharedBlock", capacity: 4096);
```

Use cases: processing very large binary files without loading them into memory, inter-process communication (IPC), and high-performance random-access I/O.

---

## Q14. What is the difference between synchronous and asynchronous file I/O?
**Answer:**
```csharp
// Synchronous — blocks the calling thread while I/O completes
string sync = File.ReadAllText("file.txt");  // thread blocked

// Asynchronous — releases the thread to do other work while I/O runs
string async_result = await File.ReadAllTextAsync("file.txt"); // thread free

// Opening a file for async I/O — use FileOptions.Asynchronous
using var fs = new FileStream("file.bin",
    FileMode.Open, FileAccess.Read,
    FileShare.Read,
    bufferSize: 4096,
    useAsync: true); // enables OS-level async I/O (IOCP on Windows)
await fs.ReadAsync(buffer, 0, buffer.Length);
```

**Important:** `useAsync: true` enables OS-level async I/O (I/O Completion Ports on Windows). Without it, the async methods still work but run on a thread pool thread internally.

---

## Q15. What is the difference between `DataContractSerializer` and `XmlSerializer`?
**Answer:**
| | `XmlSerializer` | `DataContractSerializer` |
|---|---|---|
| **Namespace** | `System.Xml.Serialization` | `System.Runtime.Serialization` |
| **Opt-in model** | Serializes all public members | Only members marked `[DataMember]` |
| **Private members** | No | Yes (with `[DataMember]`) |
| **Parameterless ctor** | Required | Not required |
| **Inheritance** | Explicit `[XmlInclude]` | `[KnownType]` |
| **Performance** | Slightly slower (XML-centric) | Faster for WCF scenarios |

```csharp
[DataContract]
class Order
{
    [DataMember] public int Id { get; set; }
    [DataMember] public string CustomerName { get; set; } = "";
    // Not serialized (no [DataMember]):
    public string InternalNotes { get; set; } = "";
}

var ds = new DataContractSerializer(typeof(Order));
using var ms = new MemoryStream();
ds.WriteObject(ms, order);
```

**Modern guidance:** For new projects, use `System.Text.Json` (JSON) or `System.Text.Json` with custom converters. XML serialization is mainly needed for legacy systems and WCF.
