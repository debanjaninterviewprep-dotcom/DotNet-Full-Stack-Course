class Motorcycle : Vehicle
{
    public bool HasSidecar { get; set; }

    public Motorcycle(string make, string model, int year, int speed, bool hasSidecar)
        : base(make, model, year, speed)
    {
        HasSidecar = hasSidecar;
    }

    public override void DisplayInfo()
    {
        base.DisplayInfo();
        Console.WriteLine($"Has Sidecar: {HasSidecar}");
    }
}
