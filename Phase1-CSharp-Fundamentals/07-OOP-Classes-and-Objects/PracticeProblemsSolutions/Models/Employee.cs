class Employee
{
    public int Id { get; private set; }
    public string Name { get; set; }
    public string Department { get; set; }
    public decimal Salary { get; set; }
    public DateTime DateOfJoining { get; set; }
    public bool IsActive { get; set; }

    public Employee(string name) : this(name, "General", 30000, DateTime.Now) { }
    public Employee(string name, string department) : this(name, department, 30000, DateTime.Now) { }
    public Employee(string name, string department, decimal salary) : this(name, department, salary, DateTime.Now) { }

    public Employee(string name, string department, decimal salary, DateTime dateOfJoining)
    {
        Id = new Random().Next(1000, 9999); // Simple random ID generator for demo
        Name = name;
        Department = department;
        Salary = salary;
        DateOfJoining = dateOfJoining;
        IsActive = true; // Default to active when created
    }

    public void DisplayInfo()
    {
        Console.WriteLine($"ID: {Id}");
        Console.WriteLine($"Name: {Name}");
        Console.WriteLine($"Department: {Department}");
        Console.WriteLine($"Salary: {Salary:C}");
        Console.WriteLine($"Date of Joining: {DateOfJoining:d}");
        Console.WriteLine($"Active: {(IsActive ? "Yes" : "No")}");
    }

    public void Promote(decimal salaryIncrease)
    {
        Salary += salaryIncrease;
        Console.WriteLine($"{Name} has been promoted! New Salary: {Salary:C}");
    }

    public void Deactivate()
    {
        IsActive = false;
        Console.WriteLine($"{Name} has been deactivated.");
    }

    public static void DisplayAllEmployees(List<Employee> employees)
    {
        Console.WriteLine("Employee List:");
        foreach (var emp in employees)
        {
            Console.WriteLine($"- {emp.Name} ({emp.Department}) - {(emp.IsActive ? "Active" : "Inactive")}");
        }
    }
}