static class ShapeHelper
{
    public static double CompareAreas(double shape1, double shape2)
    {
        return (shape1 > shape2) ? shape1 : shape2;
    }

    public static bool IsSquare(double height, double width)
    {
        return height == width;
    }
}