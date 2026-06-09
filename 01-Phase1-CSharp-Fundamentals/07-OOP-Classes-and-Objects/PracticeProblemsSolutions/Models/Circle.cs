class Circle
{
    public double Radius { get; set; }

    public Circle(double radius)
    {
        Radius = radius;
    }

    public double GetArea()
    {
        return Math.PI * Radius * Radius;
    }

    public double GetCircumference()
    {
        return 2 * Math.PI * Radius;
    }

    public void DisplayInfo()
    {
        Console.WriteLine($"Circle: Radius={Radius}, \nArea={GetArea():F2}, \nCircumference={GetCircumference():F2}");
    }
}