class Vehicle
{
    public string Make { get; set; }
    public string Model { get; set; }
    public int Year { get; set; }
    public int Speed { get; set; }

    public Vehicle(string make, string model, int year, int speed)
    {
        Make = make;
        Model = model;
        Year = year;
        Speed = speed;
    }

    public virtual void DisplayInfo()
    {
        Console.WriteLine($"Vehicle: {Year} {Make} {Model}, Speed: {Speed} km/h");
    }

    public void Accelerate(int increase)
    {
        Speed += increase;
        Console.WriteLine($"{Make} {Model} accelerated to {Speed} km/h");
    }

    public void Brake(int decrease)
    {
        Speed = Math.Max(0, Speed - decrease);
        Console.WriteLine($"{Make} {Model} slowed down to {Speed} km/h");
    }
}