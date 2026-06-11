class Circle : Shape
{
    public double Radius { get; set; }

    public Circle(double radius) : base("Circle", "Red") // Default name and color for simplicity
    {
        Radius = radius;
    }

    public override double Area()
    {
        return Math.PI * Math.Pow(Radius, 2);
    }

    public override double Perimeter()
    {
        return 2 * Math.PI * Radius;
    }

    public override void DisplayInfo()
    {
        base.DisplayInfo();
        Console.WriteLine($"Radius: {Radius}, Area: {Area()}, Perimeter: {Perimeter()}");
    }
}