//Problem 1: Write a program that asks the user for their name, age, and location, and then prints out a message that says "Hi! My name is [name]. I am [age] years old and I live in [location]."

// Console.WriteLine("What is your name?");
// string name = Console.ReadLine();
// Console.WriteLine("What is your age?");
// string ageInput = Console.ReadLine();
// Console.WriteLine("Where do you live?");
// string location = Console.ReadLine();
// Console.WriteLine($"Hi! My name is {name}. I am {ageInput} years old and I live in {location}.");

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

//Problem 2: Write a C# console program that: Asks the user for two numbers and Prints their sum, difference, product, and quotient

// Console.WriteLine("Enter the first number:");
// double firstNumber = double.Parse(Console.ReadLine());
// Console.WriteLine("Enter the second number:");
// double secondNumber = double.Parse(Console.ReadLine());
// double sum = firstNumber + secondNumber;
// double difference = firstNumber - secondNumber;
// double product = firstNumber * secondNumber;
// double quotient = firstNumber / secondNumber;
// Console.WriteLine();
// Console.WriteLine("Results:");
// Console.WriteLine();
// Console.WriteLine($"The sum of {firstNumber} and {secondNumber} is {sum}");
// Console.WriteLine($"The difference between {firstNumber} and {secondNumber} is {difference}");
// Console.WriteLine($"The product of {firstNumber} and {secondNumber} is {product}");
// Console.WriteLine($"The quotient of {firstNumber} divided by {secondNumber} is {quotient}");

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

//Problem 3: Write a program that: Takes two numbers as input and Swaps their values (the first becomes the second and vice versa) and Prints the values before and after swapping

// Console.WriteLine("Enter the first number:");
// double firstNumber = double.Parse(Console.ReadLine());
// Console.WriteLine("Enter the second number:");
// double secondNumber = double.Parse(Console.ReadLine());
// Console.WriteLine();
// Console.WriteLine($"Before swapping: firstNumber = {firstNumber}, secondNumber = {secondNumber}");
// double temp = firstNumber;
// firstNumber = secondNumber;
// secondNumber = temp;
// Console.WriteLine($"After swapping: firstNumber = {firstNumber}, secondNumber = {secondNumber}");

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

//Problem 4: Write a program that: Asks the user for a temperature in Celsius and Converts it to Fahrenheit and Kelvin and Displays all three values formatted to 2 decimal places

// Console.WriteLine("Enter a temperature in Celsius:");
// double celsius = double.Parse(Console.ReadLine());
// double fahrenheit = (celsius * 9 / 5) + 32;
// double kelvin = celsius + 273.15;
// Console.WriteLine();
// Console.WriteLine($"Temperature in Celsius: {celsius:F2} °C");
// Console.WriteLine($"Temperature in Fahrenheit: {fahrenheit:F2} °F");
// Console.WriteLine($"Temperature in Kelvin: {kelvin:F2} K");

//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//

//Problem 5: Write a program that: Takes the user's name, role, and email and Generates a formatted profile card in the console using ASCII art/box drawing

//Requirements:

// The box should have a fixed width (e.g., 36 characters inner width)
// Text should be padded properly so the right border aligns
// The "Joined" date should be auto-generated using DateTime.Now

// Console.WriteLine("Enter your name:");
// string name = Console.ReadLine();
// Console.WriteLine("Enter your role:");
// string role = Console.ReadLine();
// Console.WriteLine("Enter your email:");
// string email = Console.ReadLine();
// string joinedDate = DateTime.Now.ToString("MMMM dd, yyyy");
// string border = new string('═', 39);
// Console.WriteLine(border);
// Console.WriteLine($"║ Profile Card for {name.PadRight(19)}║");
// Console.WriteLine(border);
// Console.WriteLine($"║ Name: {name.PadRight(29)} ║");
// Console.WriteLine($"║ Role: {role.PadRight(29)} ║");
// Console.WriteLine($"║ Email: {email.PadRight(28)} ║");
// Console.WriteLine(border);
// Console.WriteLine($"║ Joined: {joinedDate.PadRight(27)} ║");
// Console.WriteLine(border);

