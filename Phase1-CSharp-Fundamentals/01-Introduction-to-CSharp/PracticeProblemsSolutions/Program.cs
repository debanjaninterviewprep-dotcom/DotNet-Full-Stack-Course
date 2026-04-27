using System;

namespace PracticeProblemsSolutions
{
    class Program
    {
        static void Main(string[] args)
        {
            // ===============================
            // Problem 1: User Introduction
            // ===============================
            Console.WriteLine("=== User Introduction ===");
            Console.Write("What is your name? ");
            string? name = Console.ReadLine();
            Console.Write("What is your age? ");
            string? ageInput = Console.ReadLine();
            Console.Write("Where do you live? ");
            string? location = Console.ReadLine();
            Console.WriteLine($"Hi! My name is {name ?? "[unknown]"}. I am {ageInput ?? "[unknown]"} years old and I live in {location ?? "[unknown]"}.");

            // ===============================
            // Problem 2: Arithmetic Operations
            // ===============================
            Console.WriteLine("\n=== Arithmetic Operations ===");
            double firstNumber = ReadDouble("Enter the first number: ");
            double secondNumber = ReadDouble("Enter the second number: ");
            Console.WriteLine($"Sum: {firstNumber + secondNumber}");
            Console.WriteLine($"Difference: {firstNumber - secondNumber}");
            Console.WriteLine($"Product: {firstNumber * secondNumber}");
            if (secondNumber != 0)
                Console.WriteLine($"Quotient: {firstNumber / secondNumber}");
            else
                Console.WriteLine("Cannot divide by zero.");

            // ===============================
            // Problem 3: Swap Two Numbers
            // ===============================
            Console.WriteLine("\n=== Swap Two Numbers ===");
            double swapA = ReadDouble("Enter the first number: ");
            double swapB = ReadDouble("Enter the second number: ");
            Console.WriteLine($"Before swapping: firstNumber = {swapA}, secondNumber = {swapB}");
            double temp = swapA;
            swapA = swapB;
            swapB = temp;
            Console.WriteLine($"After swapping: firstNumber = {swapA}, secondNumber = {swapB}");

            // ===============================
            // Problem 4: Temperature Converter
            // ===============================
            Console.WriteLine("\n=== Temperature Converter ===");
            double celsius = ReadDouble("Enter a temperature in Celsius: ");
            double fahrenheit = (celsius * 9 / 5) + 32;
            double kelvin = celsius + 273.15;
            Console.WriteLine($"Celsius: {celsius:F2} °C");
            Console.WriteLine($"Fahrenheit: {fahrenheit:F2} °F");
            Console.WriteLine($"Kelvin: {kelvin:F2} K");

            // ===============================
            // Problem 5: Profile Card
            // ===============================
            Console.WriteLine("\n=== Profile Card ===");
            Console.Write("Enter your name: ");
            string? profName = Console.ReadLine();
            Console.Write("Enter your role: ");
            string? profRole = Console.ReadLine();
            Console.Write("Enter your email: ");
            string? profEmail = Console.ReadLine();
            string joinedDate = DateTime.Now.ToString("MMMM dd, yyyy");
            string border = new string('═', 39);
            Console.WriteLine(border);
            Console.WriteLine($"║ Profile Card for {(profName ?? "").PadRight(19)}║");
            Console.WriteLine(border);
            Console.WriteLine($"║ Name: {(profName ?? "").PadRight(29)} ║");
            Console.WriteLine($"║ Role: {(profRole ?? "").PadRight(29)} ║");
            Console.WriteLine($"║ Email: {(profEmail ?? "").PadRight(28)} ║");
            Console.WriteLine(border);
            Console.WriteLine($"║ Joined: {joinedDate.PadRight(27)} ║");
            Console.WriteLine(border);
        }

        static double ReadDouble(string prompt)
        {
            double value;
            Console.Write(prompt);
            while (!double.TryParse(Console.ReadLine(), out value))
            {
                Console.Write("Invalid input. " + prompt);
            }
            return value;
        }
    }
}