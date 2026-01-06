class SudokuGenerator {
    constructor() {
        this.board = Array(9).fill(null).map(() => Array(9).fill(0));
        this.solution = Array(9).fill(null).map(() => Array(9).fill(0));
    }

    // Check if a number is valid at a given position
    isValid(board, row, col, num) {
        // Check row
        for (let x = 0; x < 9; x++) {
            if (board[row][x] === num) {
                return false;
            }
        }

        // Check column
        for (let x = 0; x < 9; x++) {
            if (board[x][col] === num) {
                return false;
            }
        }

        // Check 3x3 box
        const startRow = row - (row % 3);
        const startCol = col - (col % 3);
        for (let i = 0; i < 3; i++) {
            for (let j = 0; j < 3; j++) {
                if (board[i + startRow][j + startCol] === num) {
                    return false;
                }
            }
        }

        return true;
    }

    // Solve sudoku using backtracking
    solveSudoku(board) {
        for (let row = 0; row < 9; row++) {
            for (let col = 0; col < 9; col++) {
                if (board[row][col] === 0) {
                    for (let num = 1; num <= 9; num++) {
                        if (this.isValid(board, row, col, num)) {
                            board[row][col] = num;

                            if (this.solveSudoku(board)) {
                                return true;
                            }

                            board[row][col] = 0;
                        }
                    }
                    return false;
                }
            }
        }
        return true;
    }

    // Fill diagonal 3x3 boxes
    fillDiagonal() {
        for (let i = 0; i < 9; i += 3) {
            this.fillBox(i, i);
        }
    }

    // Fill a 3x3 box
    fillBox(row, col) {
        const numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9];
        this.shuffle(numbers);

        let num = 0;
        for (let i = 0; i < 3; i++) {
            for (let j = 0; j < 3; j++) {
                this.board[row + i][col + j] = numbers[num++];
            }
        }
    }

    // Shuffle array
    shuffle(array) {
        for (let i = array.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [array[i], array[j]] = [array[j], array[i]];
        }
    }

    // Generate a complete valid Sudoku board
    generateComplete() {
        this.board = Array(9).fill(null).map(() => Array(9).fill(0));
        this.fillDiagonal();
        this.solveSudoku(this.board);
        return this.board;
    }

    // Remove numbers based on difficulty
    removeNumbers(difficulty) {
        let attempts;
        switch (difficulty) {
            case 'easy':
                attempts = 40;
                break;
            case 'medium':
                attempts = 50;
                break;
            case 'hard':
                attempts = 55;
                break;
            case 'expert':
                attempts = 60;
                break;
            default:
                attempts = 50;
        }

        while (attempts > 0) {
            const row = Math.floor(Math.random() * 9);
            const col = Math.floor(Math.random() * 9);

            if (this.board[row][col] !== 0) {
                this.board[row][col] = 0;
                attempts--;
            }
        }
    }

    // Generate a new puzzle
    generate(difficulty = 'medium') {
        this.generateComplete();
        this.solution = this.board.map(row => [...row]);
        this.removeNumbers(difficulty);
        return {
            puzzle: this.board.map(row => [...row]),
            solution: this.solution
        };
    }

    // Check if the current board state is valid
    checkBoard(board) {
        for (let row = 0; row < 9; row++) {
            for (let col = 0; col < 9; col++) {
                if (board[row][col] !== 0) {
                    const num = board[row][col];
                    board[row][col] = 0;
                    if (!this.isValid(board, row, col, num)) {
                        board[row][col] = num;
                        return false;
                    }
                    board[row][col] = num;
                }
            }
        }
        return true;
    }

    // Check if puzzle is complete
    isComplete(board) {
        for (let row = 0; row < 9; row++) {
            for (let col = 0; col < 9; col++) {
                if (board[row][col] === 0) {
                    return false;
                }
            }
        }
        return this.checkBoard(board);
    }
}
