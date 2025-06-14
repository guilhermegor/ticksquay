"""Unit tests for Calculator class with mocking examples."""

from typing import Protocol
import unittest
from unittest.mock import MagicMock


class ApiClient(Protocol):
    """Protocol for API client objects."""

    def get_value(self) -> float:
        """Get a value from the API."""
        ...


class Calculator:
    """A simple calculator class for demonstration purposes."""

    def add(self, a: float, b: float) -> float:
        """Add two numbers together.

        Args:
            a: First number to add
            b: Second number to add

        Returns
        -------
            The sum of a and b
        """
        return a + b

    def fetch_remote_value(self, api_client: ApiClient) -> float:
        """Fetch a value from a remote API and add 10 to it.

        Args:
            api_client: API client object with get_value method

        Returns
        -------
            The remote value plus 10
        """
        return api_client.get_value() + 10


class TestCalculator(unittest.TestCase):
    """Test cases for the Calculator class."""

    def setUp(self) -> None:
        """Set up test fixtures before each test method."""
        self.calc = Calculator()

    def test_add(self) -> None:
        """Test the add method with positive numbers."""
        result = self.calc.add(2, 3)
        self.assertEqual(result, 5)

    def test_fetch_remote_value(self) -> None:
        """Test fetch_remote_value method using a mock API client."""
        mock_api_client = MagicMock()
        mock_api_client.get_value.return_value = 5

        result = self.calc.fetch_remote_value(mock_api_client)

        mock_api_client.get_value.assert_called_once()
        self.assertEqual(result, 15)


if __name__ == '__main__':
    unittest.main()
