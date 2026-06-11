class HourlyEmployee : Employee
{
    public decimal HourlyRate { get; set; }
    public int HoursWorked { get; set; }

    public int OvertimeHours
    {
        get
        {
            return HoursWorked > 40 ? HoursWorked - 40 : 0;
        }
    }

    public HourlyEmployee(int id, string name, string department, decimal hourlyRate, int hoursWorked)
        : base(id, name, department)
    {
        HourlyRate = hourlyRate;
        HoursWorked = hoursWorked;
    }

    public override double CalculatePay()
    {
        return (double)(HourlyRate * HoursWorked) + (OvertimeHours > 0 ? (double)(HourlyRate * 1.5m * OvertimeHours) : 0);
    }
    
    public override string GetRole()
    {
        return "Hourly Employee";
    }
}