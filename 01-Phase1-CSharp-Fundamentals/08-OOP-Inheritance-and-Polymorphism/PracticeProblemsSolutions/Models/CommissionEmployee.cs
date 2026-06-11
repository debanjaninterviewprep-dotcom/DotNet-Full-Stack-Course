class CommissionEmployee : Employee
{
    public double baseSalary { get; set; }
    public double commissionRate { get; set; }
    public double salesAmount { get; set; }

    public CommissionEmployee(int id, string name, string department, double baseSalary, double commissionRate, double salesAmount)
        : base(id, name, department)
    {
        this.baseSalary = baseSalary;
        this.commissionRate = commissionRate;
        this.salesAmount = salesAmount;
    }

    public override double CalculatePay()
    {
        return baseSalary + (commissionRate * salesAmount);
    }

    public override string GetRole()
    {
        return "Commission Employee";
    }
}