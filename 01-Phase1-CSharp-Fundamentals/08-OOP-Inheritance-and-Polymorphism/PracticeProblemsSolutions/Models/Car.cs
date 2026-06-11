class Car : Vehicle
{
    public int NumberOfDoors { get; set; }

    public Car(string make, string model, int year, int speed, int numberOfDoors)
        : base(make, model, year, speed)
    {
        NumberOfDoors = numberOfDoors;
    }

    public override void DisplayInfo()
    {
        base.DisplayInfo();
        Console.WriteLine($"Number of Doors: {NumberOfDoors}");
    }
}