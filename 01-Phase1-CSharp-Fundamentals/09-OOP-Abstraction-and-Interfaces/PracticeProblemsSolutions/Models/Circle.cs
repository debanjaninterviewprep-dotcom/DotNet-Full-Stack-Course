class Circle : Shape
{
    public double Radius { get; set; }

    public override double Area => Math.PI * Radius * Radius;

    public override double Perimeter => 2 * Math.PI * Radius;
}