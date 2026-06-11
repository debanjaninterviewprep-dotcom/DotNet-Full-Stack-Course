abstract class Shape
{
    public abstract double Area { get; }
    public abstract double Perimeter { get; }

    public virtual void Describe()
    {
        Console.WriteLine($"\nShape: {GetType().Name}, \nArea: {Area:F2}, \nPerimeter: {Perimeter:F2}");
    }
}