class Triangle : Shape
{
    public double Base { get; set; }
    public double Height { get; set; }
    public double SideA { get; set; }
    public double SideB { get; set; }
    public double SideC { get; set; }

    public Triangle(double baseLength, double height, double sideA, double sideB, double sideC) : base("Triangle", "Green") // Default name and color for simplicity
    {
        Base = baseLength;
        Height = height;
        SideA = sideA;
        SideB = sideB;
        SideC = sideC;
    }

    public override double Area()
    {
        return 0.5 * Base * Height;
    }

    public override double Perimeter()
    {
        return SideA + SideB + SideC;
    }
}