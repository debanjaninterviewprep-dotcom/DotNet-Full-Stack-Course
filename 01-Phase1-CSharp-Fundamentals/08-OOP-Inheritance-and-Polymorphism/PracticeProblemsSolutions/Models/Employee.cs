class Employee
{
    public int id { get; set; }
    public string name { get; set; }
    public string department { get; set; }

    public Employee(int id, string name, string department)
    {
        this.id = id;
        this.name = name;
        this.department = department;
    }

    public virtual double CalculatePay()
    {
        return 0; // Base implementation, should be overridden by subclasses
    }

    public virtual string GetRole()
    {
        return "Employee";
    }
}