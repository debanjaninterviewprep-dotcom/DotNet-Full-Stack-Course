using System;

namespace PracticeProblemsSolutions
{
	class Program
	{
		static void Main(string[] args)
		{
			// ===============================
			// Problem 1: Number Classifier
			// ===============================
			// Ask user for a number and classify as positive/negative/zero and even/odd using if-else and modulus operator.

			Console.WriteLine("Welcome to the Number Classifier!");

			Console.Write("Enter a number: ");
			int number = int.Parse(Console.ReadLine());
			if (number > 0)
			{
				Console.WriteLine("The number is positive.");
			}
			else if (number < 0)
			{
				Console.WriteLine("The number is negative.");
			}
			else
			{
				Console.WriteLine("The number is zero.");
			}

			if (number % 2 == 0)
			{
				Console.WriteLine("The number is even.");
			}
			else
			{
				Console.WriteLine("The number is odd.");
			}

			// ===============================
			// Problem 2: Calculator with Switch
			// ===============================
			// Build a calculator taking two numbers and an operator, using switch statement and do-while loop for repeat functionality.

			Console.WriteLine("Welcome to the simple calculator!");

			do
			{
				Console.Write("Enter first number: ");
				double num1 = double.Parse(Console.ReadLine());

				Console.Write("Enter second number: ");
				double num2 = double.Parse(Console.ReadLine());

				Console.Write("Enter operator (+, -, *, /): ");
				char op = Console.ReadLine()[0];

				double result = 0;
				bool validOperation = true;

				switch (op)
				{
					case '+':
						result = num1 + num2;
						break;
					case '-':
						result = num1 - num2;
						break;
					case '*':
						result = num1 * num2;
						break;
					case '/':
						if (num2 != 0)
						{
							result = num1 / num2;
						}
						else
						{
							Console.WriteLine("Error: Division by zero is not allowed.");
							validOperation = false;
						}
						break;
					default:
						Console.WriteLine("Invalid operator.");
						validOperation = false;
						break;
				}

				if (validOperation)
				{
					Console.WriteLine("Result: " + result);
					Console.WriteLine("Do you want to perform another calculation? (y/n)");
				}

			} while (true && Console.ReadLine().ToLower() == "y"); // Continue if user inputs 'y'


			// ===============================
			// Problem 3: Number Guessing Game
			// ===============================
			// Generate random number between 1-100, let user guess with 7 attempts, report too high/too low, track attempts.

			Console.WriteLine("Welcome to the Number Guessing Game!");
			Console.WriteLine("I have selected a random number between 1 and 100. Can you guess it in 7 attempts?");


			do
			{
				var rng = new Random();
				int randomNum = rng.Next(1, 101); // returns 1..100
				int attempts = 0;
				int guess = 0;

				while (attempts < 7)
				{
					Console.Write("Enter your guess: ");
					guess = int.Parse(Console.ReadLine());
					attempts++;

					if (guess == randomNum)
					{
						Console.WriteLine("Congratulations! You guessed the number.");
						break;
					}
					else if (guess < randomNum)
					{
						Console.WriteLine("Too low.");
					}
					else
					{
						Console.WriteLine("Too high.");
					}
				}

				if (guess == randomNum)
				{
					Console.WriteLine("You won!");
				}
				else
				{
					Console.WriteLine("You lost. The number was " + randomNum);
				}
				Console.WriteLine("Do you want to play again? (y/n)");
			} while (Console.ReadLine().ToLower() == "y");


			// ===============================
			// Problem 4: Star Pattern Printer
			// ===============================
			// Print 4 different patterns (right triangle, inverted triangle, pyramid, diamond) using nested for loops and user-selected choice.

			Console.WriteLine("Star Pattern Printer");
			int patternChoice;
			do
			{
				Console.WriteLine("Choose a pattern:\n 1) Right triangle\n 2) Inverted triangle\n 3) Pyramid\n 4) Diamond\n 0) Skip");
				Console.Write("Enter choice (0-4): ");
				string? choiceInput = Console.ReadLine();
				if (!int.TryParse(choiceInput, out patternChoice))
				{
					Console.WriteLine("Invalid choice. Try again.");
					continue;
				}
				if (patternChoice == 0) break;
				Console.Write("Enter size (positive integer): ");
				string? sizeInput = Console.ReadLine();
				if (!int.TryParse(sizeInput, out int size) || size <= 0)
				{
					Console.WriteLine("Invalid size. Try again.");
					continue;
				}
				switch (patternChoice)
				{
					case 1: // Right triangle
						for (int i = 1; i <= size; i++)
						{
							Console.WriteLine(new string('*', i));
						}
						break;
					case 2: // Inverted triangle
						for (int i = size; i >= 1; i--)
						{
							Console.WriteLine(new string('*', i));
						}
						break;
					case 3: // Pyramid
						for (int i = 1; i <= size; i++)
						{
							Console.Write(new string(' ', size - i));
							Console.WriteLine(new string('*', 2 * i - 1));
						}
						break;
					case 4: // Diamond
						for (int i = 1; i <= size; i++)
						{
							Console.Write(new string(' ', size - i));
							Console.WriteLine(new string('*', 2 * i - 1));
						}
						for (int i = size - 1; i >= 1; i--)
						{
							Console.Write(new string(' ', size - i));
							Console.WriteLine(new string('*', 2 * i - 1));
						}
						break;
					default:
						Console.WriteLine("Invalid choice.");
						break;
				}
				Console.WriteLine();
			} while (true);


			// ===============================
			// Problem 5: FizzBuzz Extended
			// For range 1-n, print Task/Flow/TaskFlow/Pro based on divisibility by 3/5/7, calculate and display statistics.

			Console.WriteLine("FizzBuzz Extended (Task/Flow/TaskFlow/Pro)");
			Console.Write("Enter n (positive integer): ");
			string? nInput = Console.ReadLine();
			if (int.TryParse(nInput, out int n) && n > 0)
			{
				int countTask = 0, countFlow = 0, countTaskFlow = 0, countPro = 0, countOther = 0;
				for (int i = 1; i <= n; i++)
				{
					if (i % 3 == 0 && i % 5 == 0)
					{
						Console.WriteLine("TaskFlow");
						countTaskFlow++;
					}
					else if (i % 3 == 0)
					{
						Console.WriteLine("Task");
						countTask++;
					}
					else if (i % 5 == 0)
					{
						Console.WriteLine("Flow");
						countFlow++;
					}
					else if (i % 7 == 0)
					{
						Console.WriteLine("Pro");
						countPro++;
					}
					else
					{
						Console.WriteLine(i);
						countOther++;
					}
				}
				Console.WriteLine();
				Console.WriteLine("--- Statistics ---");
				Console.WriteLine($"Range: 1 to {n}");
				Console.WriteLine($"Task (3 only): {countTask}");
				Console.WriteLine($"Flow (5 only): {countFlow}");
				Console.WriteLine($"TaskFlow (3 & 5): {countTaskFlow}");
				Console.WriteLine($"Pro (7 only): {countPro}");
				Console.WriteLine($"Other numbers: {countOther}");
			}
			else
			{
				Console.WriteLine("Invalid input for n.");
			}

		}
	}
}
