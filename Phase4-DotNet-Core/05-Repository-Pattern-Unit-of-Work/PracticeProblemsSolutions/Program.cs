using System;

namespace PracticeProblemsSolutions
{
	class Program
	{
		static void Main(string[] args)
		{
			// ===============================
			// Problem 1: Generic Repository Implementation
			// ===============================
			// IGenericRepository<T> with GetById/GetAll/Find/Add/Update/Remove, InMemoryRepository for multiple types.

			// TODO: Write your solution here


			// ===============================
			// Problem 2: Specific Repository with Complex Queries
			// ===============================
			// IProductRepository extending generic repo with GetByCategoryAsync, SearchAsync, pagination returning PagedResult<T>.

			// TODO: Write your solution here


			// ===============================
			// Problem 3: Unit of Work with Transaction Management
			// ===============================
			// IUnitOfWork coordinating multiple repos, atomic SaveChanges, rollback on exception (insufficient stock scenario).

			// TODO: Write your solution here


			// ===============================
			// Problem 4: Specification Pattern
			// ===============================
			// Abstract Specification<T>, AND/OR/NOT composition, ProductSpec, InStockSpec, composable query criteria.

			// TODO: Write your solution here


			// ===============================
			// Problem 5: Complete Data Access Layer
			// ===============================
			// Generic repo, specific repos, unit of work, specifications, create customer -> browse -> order -> history -> report.

			// TODO: Write your solution here

		}
	}
}
