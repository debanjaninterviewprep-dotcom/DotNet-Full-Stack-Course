class Rectangle
{
    public double Height { get; set; }
    public double Width { get; set; }

    public Rectangle(double height, double width)
    {
        Height = height;
        Width = width;
    }

    public double GetArea()
    {
        return Height * Width;
    }

    public double GetPerimeter()
    {
        return 2 * (Height + Width);
    }

    public void DisplayInfo()
    {
        Console.WriteLine($"Rectangle: Height={Height}, Width={Width}, \nArea={GetArea()}, \nPerimeter={GetPerimeter()}, \nIsSquare={ShapeHelper.IsSquare(Height, Width)}");
    }
}