class SalariedEmployee : Employee
{
    public double monthlySalary { get; set; }
    public double bonus { get; set; }

    public SalariedEmployee(int id, string name, string department, double salary)
        : base(id, name, department)
    {
        this.monthlySalary = salary;
    }

    public override double CalculatePay()
    {
        return monthlySalary + bonus;
    }

    public override string GetRole()
    {
        return "Salaried Employee";
    }
}