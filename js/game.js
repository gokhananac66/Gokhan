class SudokuGame {
    constructor() {
        this.generator = new SudokuGenerator();
        this.currentBoard = null;
        this.solution = null;
        this.initialBoard = null;
        this.selectedCell = null;
        this.difficulty = 'medium';
        this.timer = 0;
        this.timerInterval = null;
        this.mistakes = 0;
        this.maxMistakes = 3;
        this.moveHistory = [];

        this.initializeGame();
        this.attachEventListeners();
    }

    initializeGame() {
        const { puzzle, solution } = this.generator.generate(this.difficulty);
        this.currentBoard = puzzle;
        this.solution = solution;
        this.initialBoard = puzzle.map(row => [...row]);
        this.renderBoard();
        this.startTimer();
    }

    renderBoard() {
        const boardElement = document.getElementById('sudoku-board');
        boardElement.innerHTML = '';

        for (let row = 0; row < 9; row++) {
            for (let col = 0; col < 9; col++) {
                const cell = document.createElement('div');
                cell.className = 'cell';
                cell.dataset.row = row;
                cell.dataset.col = col;

                // Add border classes for 3x3 boxes
                if (row % 3 === 2 && row !== 8) cell.classList.add('border-bottom');
                if (col % 3 === 2 && col !== 8) cell.classList.add('border-right');

                const value = this.currentBoard[row][col];
                if (value !== 0) {
                    cell.textContent = value;
                    if (this.initialBoard[row][col] !== 0) {
                        cell.classList.add('fixed');
                    }
                }

                cell.addEventListener('click', () => this.selectCell(row, col));
                boardElement.appendChild(cell);
            }
        }
    }

    selectCell(row, col) {
        // Don't allow selection of fixed cells
        if (this.initialBoard[row][col] !== 0) {
            return;
        }

        // Remove previous selection
        const cells = document.querySelectorAll('.cell');
        cells.forEach(cell => cell.classList.remove('selected'));

        // Select new cell
        const cell = document.querySelector(`[data-row="${row}"][data-col="${col}"]`);
        cell.classList.add('selected');
        this.selectedCell = { row, col };
    }

    placeNumber(num) {
        if (!this.selectedCell) {
            return;
        }

        const { row, col } = this.selectedCell;

        // Don't allow changing fixed cells
        if (this.initialBoard[row][col] !== 0) {
            return;
        }

        // Save move for undo
        this.moveHistory.push({
            row,
            col,
            oldValue: this.currentBoard[row][col],
            newValue: num
        });

        // Update board
        this.currentBoard[row][col] = num;

        // Check if the move is wrong
        if (num !== 0 && this.solution[row][col] !== num) {
            this.mistakes++;
            this.updateMistakes();

            const cell = document.querySelector(`[data-row="${row}"][data-col="${col}"]`);
            cell.classList.add('wrong');
            setTimeout(() => cell.classList.remove('wrong'), 500);

            if (this.mistakes >= this.maxMistakes) {
                this.gameOver();
                return;
            }
        }

        // Re-render board
        this.renderBoard();

        // Re-select the cell
        const cell = document.querySelector(`[data-row="${row}"][data-col="${col}"]`);
        if (cell) {
            cell.classList.add('selected');
        }

        // Check if puzzle is complete
        if (this.generator.isComplete(this.currentBoard)) {
            this.winGame();
        }
    }

    undo() {
        if (this.moveHistory.length === 0) {
            return;
        }

        const lastMove = this.moveHistory.pop();
        this.currentBoard[lastMove.row][lastMove.col] = lastMove.oldValue;
        this.renderBoard();
    }

    getHint() {
        // Find an empty cell and fill it with the correct number
        for (let row = 0; row < 9; row++) {
            for (let col = 0; col < 9; col++) {
                if (this.currentBoard[row][col] === 0 && this.initialBoard[row][col] === 0) {
                    this.selectedCell = { row, col };
                    this.placeNumber(this.solution[row][col]);
                    return;
                }
            }
        }
    }

    checkSolution() {
        let hasErrors = false;
        const cells = document.querySelectorAll('.cell');

        cells.forEach(cell => {
            const row = parseInt(cell.dataset.row);
            const col = parseInt(cell.dataset.col);
            const value = this.currentBoard[row][col];

            if (value !== 0 && value !== this.solution[row][col]) {
                cell.classList.add('error');
                hasErrors = true;
            } else {
                cell.classList.remove('error');
            }
        });

        if (!hasErrors) {
            alert('All filled cells are correct! Keep going!');
        }
    }

    startTimer() {
        this.timer = 0;
        this.updateTimer();
        this.timerInterval = setInterval(() => {
            this.timer++;
            this.updateTimer();
        }, 1000);
    }

    updateTimer() {
        const minutes = Math.floor(this.timer / 60);
        const seconds = this.timer % 60;
        document.getElementById('timer').textContent =
            `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
    }

    updateMistakes() {
        document.getElementById('mistakes').textContent = `${this.mistakes}/${this.maxMistakes}`;
    }

    winGame() {
        clearInterval(this.timerInterval);
        const modal = document.getElementById('win-modal');
        document.getElementById('final-time').textContent = document.getElementById('timer').textContent;
        modal.style.display = 'flex';
    }

    gameOver() {
        clearInterval(this.timerInterval);
        alert('Game Over! Too many mistakes. Try again!');
        this.newGame();
    }

    newGame() {
        clearInterval(this.timerInterval);
        this.mistakes = 0;
        this.updateMistakes();
        this.moveHistory = [];
        this.selectedCell = null;
        document.getElementById('win-modal').style.display = 'none';
        this.initializeGame();
    }

    setDifficulty(difficulty) {
        this.difficulty = difficulty;
        document.getElementById('current-difficulty').textContent =
            difficulty.charAt(0).toUpperCase() + difficulty.slice(1);

        // Update active button
        document.querySelectorAll('.difficulty-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-difficulty="${difficulty}"]`).classList.add('active');
    }

    attachEventListeners() {
        // Number pad buttons
        document.querySelectorAll('.number-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const num = parseInt(btn.dataset.number);
                this.placeNumber(num);
            });
        });

        // Keyboard input
        document.addEventListener('keydown', (e) => {
            if (e.key >= '1' && e.key <= '9') {
                this.placeNumber(parseInt(e.key));
            } else if (e.key === 'Backspace' || e.key === 'Delete' || e.key === '0') {
                this.placeNumber(0);
            }
        });

        // Control buttons
        document.getElementById('new-game-btn').addEventListener('click', () => {
            this.newGame();
        });

        document.getElementById('hint-btn').addEventListener('click', () => {
            this.getHint();
        });

        document.getElementById('undo-btn').addEventListener('click', () => {
            this.undo();
        });

        document.getElementById('check-btn').addEventListener('click', () => {
            this.checkSolution();
        });

        // Difficulty buttons
        document.querySelectorAll('.difficulty-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                this.setDifficulty(btn.dataset.difficulty);
                this.newGame();
            });
        });

        // Play again button
        document.getElementById('play-again-btn').addEventListener('click', () => {
            this.newGame();
        });
    }
}

// Initialize game when page loads
document.addEventListener('DOMContentLoaded', () => {
    new SudokuGame();
});
