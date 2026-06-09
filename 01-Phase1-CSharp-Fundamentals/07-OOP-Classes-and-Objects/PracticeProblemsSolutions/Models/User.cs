class User
{
    private static int Id_count = 0;   // ✅ Static counter for unique IDs
    public int Id { get; private set; }
    public string Name { get; set; }
    public string Email { get; set; }
    public string Role { get; set; }

    public User(string name, string email, string role)
    {
        Id = ++Id_count;   // ✅ Assign unique ID
        Name = name;
        Email = email;
        Role = role;
    }

    public void DisplayInfo()
    {
        Console.WriteLine($"ID: {Id}, Name: {Name}, Email: {Email}, Role: {Role}");
    }
}