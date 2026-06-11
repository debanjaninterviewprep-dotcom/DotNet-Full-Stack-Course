class Shape
{
    public string Name { get; set; }
    public string Color { get; set; }

    public Shape(string name, string color)
    {
        Name = name;
        Color = color;
    }

    public virtual double Area()
    {
        return 0;
    }
    public virtual double Perimeter()
    {
        return 0;
    }
    public virtual void DisplayInfo()
    {
        Console.WriteLine($"Shape: {Name}, Color: {Color}");
    }
}
