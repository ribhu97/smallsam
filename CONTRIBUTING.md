# Contributing to Small Sam

Thank you for your interest in contributing to Small Sam! This document provides comprehensive guidelines for contributing to our multi-agent AI system for Fantasy Premier League analysis.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Architecture Guidelines](#architecture-guidelines)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)
- [Release Process](#release-process)

## 🤝 Code of Conduct

### Our Standards

We are committed to fostering an inclusive and welcoming community. Contributors are expected to:

- **Be Respectful**: Treat all community members with dignity and professionalism
- **Be Collaborative**: Embrace constructive feedback and different perspectives
- **Be Inclusive**: Welcome newcomers and maintain an accessible environment
- **Focus on Technical Merit**: Evaluate contributions based on technical quality and project alignment

### Unacceptable Behavior

- Harassment, discrimination, or exclusionary behavior
- Personal attacks or inflammatory comments
- Spam, promotional content, or off-topic discussions
- Sharing private information without explicit consent

**Reporting**: Contact the maintainers at conduct@smallsam.dev for any violations.

## 🚀 Getting Started

### Prerequisites

Before contributing, ensure you have the following tools installed:

**Required Tools**
- **Git**: 2.30+ with configured GPG signing
- **Docker**: 20.10+ with Docker Compose 2.0+
- **Python**: 3.11+ with pyenv for version management
- **Node.js**: 18+ with npm 8+
- **Pre-commit**: For automated code quality checks

**Recommended Tools**
- **VS Code**: With Python, TypeScript, and Docker extensions
- **Postman/Insomnia**: For API testing and development
- **DBeaver/pgAdmin**: For database inspection and debugging

### Development Environment Setup

1. **Fork and Clone Repository**
   ```bash
   # Fork the repository on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/smallsam.git
   cd smallsam
   
   # Add upstream remote for syncing
   git remote add upstream https://github.com/ribhu97/smallsam.git
   ```

2. **Environment Configuration**
   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Generate development secrets
   python scripts/generate_dev_secrets.py
   
   # Configure your .env file with:
   # - OpenAI API key for agent development
   # - Local database credentials
   # - Debug logging settings
   ```

3. **Pre-commit Hooks Installation**
   ```bash
   # Install pre-commit framework
   pip install pre-commit
   
   # Install project hooks
   pre-commit install
   pre-commit install --hook-type commit-msg
   
   # Verify installation
   pre-commit run --all-files
   ```

4. **Infrastructure Bootstrap**
   ```bash
   # Start development infrastructure
   docker-compose -f docker-compose.dev.yml up -d
   
   # Initialize databases
   cd backend && alembic upgrade head
   cd ../data-orchestration && python scripts/init_vector_db.py
   
   # Verify infrastructure health
   curl http://localhost:8000/api/v1/health
   ```

5. **Service-Specific Setup**

   **Backend Service**
   ```bash
   cd backend
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements-dev.txt
   pre-commit install --hook-type pre-push
   ```

   **Frontend Service**
   ```bash
   cd frontend
   npm install
   npm run build
   npm run type-check
   ```

   **Agent Framework**
   ```bash
   cd agent-framework
   python -m venv venv
   source venv/bin/activate
   pip install -e .
   python -m pytest tests/ -v
   ```

## 🔄 Development Workflow

### Git Workflow Standards

We follow a **GitHub Flow** model with the following conventions:

**Branch Naming Convention**
```
feature/FPL-123-add-injury-tracking     # New features
bugfix/FPL-456-fix-agent-timeout       # Bug fixes
hotfix/FPL-789-critical-data-loss      # Critical production fixes
chore/FPL-101-update-dependencies      # Maintenance tasks
docs/FPL-202-api-documentation         # Documentation updates
```

**Commit Message Standards**

We use [Conventional Commits](https://www.conventionalcommits.org/) with the following format:

```
type(scope): description

[optional body]

[optional footer(s)]
```

**Commit Types**
- `feat`: New feature implementation
- `fix`: Bug fix or issue resolution
- `docs`: Documentation changes
- `style`: Code formatting (no logic changes)
- `refactor`: Code restructuring without behavior changes
- `perf`: Performance improvements
- `test`: Test additions or modifications
- `chore`: Build process or auxiliary tool changes

**Examples**
```bash
feat(agents): implement news sentiment analysis agent

Add specialized agent for processing news sentiment to improve
transfer recommendations. Integrates with existing RAG pipeline
and includes confidence scoring.

Closes #FPL-234

fix(api): resolve race condition in concurrent agent queries

Previously, concurrent requests could interfere with agent state
management, causing inconsistent responses. This fix implements
proper request isolation using correlation IDs.

Fixes #FPL-567
```

### Development Process

1. **Issue Assignment**
   ```bash
   # Comment on the issue to request assignment
   # Wait for maintainer approval before starting work
   ```

2. **Feature Development**
   ```bash
   # Create feature branch from main
   git checkout main
   git pull upstream main
   git checkout -b feature/FPL-123-descriptive-name
   
   # Make incremental commits with clear messages
   git add .
   git commit -m "feat(scope): implement core functionality"
   
   # Push regularly to share progress
   git push origin feature/FPL-123-descriptive-name
   ```

3. **Code Review Preparation**
   ```bash
   # Rebase against latest main
   git checkout main
   git pull upstream main
   git checkout feature/FPL-123-descriptive-name
   git rebase main
   
   # Run comprehensive tests
   make test-all
   make lint-all
   make security-scan
   
   # Verify documentation updates
   make docs-build
   ```

## 🏗️ Architecture Guidelines

### Service Boundaries

When contributing to the Small Sam, maintain clear architectural boundaries:

**Data Orchestration Service**
- **Responsibility**: External data ingestion and preprocessing
- **Dependencies**: Should not directly query application database
- **Communication**: Publishes events via message queue
- **Testing**: Mock external APIs, test data transformation logic

**Agent Framework**
- **Responsibility**: Multi-agent reasoning and query processing
- **Dependencies**: Read-only access to all data stores
- **Communication**: Synchronous API calls with timeout handling
- **Testing**: Unit test individual agents, integration test workflows

**Backend API Service**
- **Responsibility**: Business logic and API orchestration
- **Dependencies**: Coordinates between data layer and agent framework
- **Communication**: REST API with standard HTTP semantics
- **Testing**: API contract testing, database integration testing

### Design Principles

**1. Separation of Concerns**
```python
# Good: Clear responsibility separation
class PlayerStatsService:
    def __init__(self, db_session: Session, cache: RedisClient):
        self._db = db_session
        self._cache = cache
    
    def get_player_stats(self, player_id: int) -> PlayerStats:
        # Single responsibility: fetch and return player data
        pass

# Bad: Mixed concerns
class PlayerService:
    def get_player_and_send_email_and_log(self, player_id: int):
        # Multiple responsibilities violate SRP
        pass
```

**2. Dependency Injection**
```python
# Good: Dependencies injected, easily testable
def create_stats_agent(
    db_client: DatabaseClient,
    llm_client: LLMClient,
    logger: Logger
) -> StatsAgent:
    return StatsAgent(db_client, llm_client, logger)

# Bad: Hard-coded dependencies
class StatsAgent:
    def __init__(self):
        self.db = PostgreSQLClient()  # Tightly coupled
        self.llm = OpenAIClient()     # Hard to test
```

**3. Error Handling Patterns**
```python
# Good: Explicit error handling with context
async def process_agent_query(query: str) -> AgentResponse:
    try:
        context = await parse_query(query)
        result = await orchestrator.process(context)
        return AgentResponse(success=True, data=result)
    except ValidationError as e:
        logger.warning("Invalid query format", extra={"query": query, "error": str(e)})
        return AgentResponse(success=False, error="Invalid query format")
    except TimeoutError as e:
        logger.error("Agent processing timeout", extra={"query": query, "timeout": e.timeout})
        return AgentResponse(success=False, error="Processing timeout")
    except Exception as e:
        logger.error("Unexpected agent error", extra={"query": query, "error": str(e)})
        return AgentResponse(success=False, error="Internal processing error")
```

### Database Design Standards

**Migration Practices**
```python
# Good: Backwards compatible migration
def upgrade():
    # Add new column with default value
    op.add_column('players', sa.Column('injury_status', sa.String(50), default='fit'))
    
    # Populate existing rows
    op.execute("UPDATE players SET injury_status = 'fit' WHERE injury_status IS NULL")
    
    # Make column non-nullable after population
    op.alter_column('players', 'injury_status', nullable=False)

# Bad: Breaking migration
def upgrade():
    # This breaks existing deployments
    op.add_column('players', sa.Column('injury_status', sa.String(50), nullable=False))
```

**Query Optimization Guidelines**
```python
# Good: Efficient query with proper indexing
@cache(ttl=300)  # 5-minute cache
def get_top_players_by_position(position: str, limit: int = 10) -> List[Player]:
    return db.session.query(Player)\
        .filter(Player.position == position)\
        .filter(Player.minutes_played > 270)  # Minimum playing time\
        .order_by(Player.total_points.desc())\
        .limit(limit)\
        .options(selectinload(Player.team))\  # Eager load relationships
        .all()

# Bad: N+1 query problem
def get_players_with_teams():
    players = db.session.query(Player).all()
    for player in players:
        print(player.team.name)  # Triggers individual queries
```

## 📏 Code Standards

### Python Code Standards

**Code Formatting**
- **Black**: Line length 88 characters, double quotes for strings
- **isort**: Import sorting with profile `black`
- **flake8**: Extended with plugins for complexity and naming

```python
# .flake8 configuration
[flake8]
max-line-length = 88
extend-ignore = E203, W503, E501
max-complexity = 10
select = C,E,F,W,B,B901,B902,B903
```

**Type Annotations**
All new Python code must include comprehensive type annotations:

```python
# Good: Complete type annotations
from typing import Optional, Dict, List, Union
from datetime import datetime

def calculate_player_form(
    player_id: int,
    gameweeks: int = 5,
    weights: Optional[Dict[str, float]] = None
) -> Dict[str, Union[float, str]]:
    """Calculate weighted form score for a player.
    
    Args:
        player_id: Unique player identifier
        gameweeks: Number of recent gameweeks to analyze
        weights: Custom weights for different metrics
        
    Returns:
        Dictionary containing form score and grade
        
    Raises:
        PlayerNotFoundError: If player_id doesn't exist
        ValidationError: If gameweeks is invalid
    """
    if weights is None:
        weights = {"points": 0.4, "minutes": 0.3, "bonus": 0.3}
    
    # Implementation with proper error handling
    ...

# Bad: Missing type annotations
def calculate_form(player_id, gameweeks=5):
    # No type information, unclear return type
    pass
```

**Error Handling Standards**
```python
# Good: Specific exception types with context
class FPLAssistantError(Exception):
    """Base exception for Small Sam errors."""
    pass

class PlayerNotFoundError(FPLAssistantError):
    """Raised when player lookup fails."""
    
    def __init__(self, player_id: int):
        self.player_id = player_id
        super().__init__(f"Player {player_id} not found")

class AgentTimeoutError(FPLAssistantError):
    """Raised when agent processing exceeds timeout."""
    
    def __init__(self, agent_name: str, timeout_seconds: int):
        self.agent_name = agent_name
        self.timeout_seconds = timeout_seconds
        super().__init__(f"Agent {agent_name} timed out after {timeout_seconds}s")

# Usage with proper context
try:
    player_data = await get_player_stats(player_id)
except PlayerNotFoundError as e:
    logger.warning("Player lookup failed", extra={"player_id": e.player_id})
    raise HTTPException(status_code=404, detail="Player not found")
```

**Logging Standards**
```python
import structlog

# Configure structured logging
logger = structlog.get_logger(__name__)

# Good: Structured logging with context
async def process_transfer_recommendation(user_id: int, constraints: TransferConstraints):
    logger.info(
        "Processing transfer recommendation",
        user_id=user_id,
        budget=constraints.budget,
        transfers_remaining=constraints.transfers_remaining
    )
    
    try:
        recommendations = await agent_framework.get_recommendations(constraints)
        logger.info(
            "Transfer recommendations generated",
            user_id=user_id,
            recommendation_count=len(recommendations),
            processing_time_ms=timer.elapsed_ms
        )
        return recommendations
    except Exception as e:
        logger.error(
            "Transfer recommendation failed",
            user_id=user_id,
            error=str(e),
            error_type=type(e).__name__
        )
        raise
```

### TypeScript Code Standards

**React Component Standards**
```typescript
// Good: Properly typed React component with error boundaries
interface PlayerCardProps {
  player: Player;
  onTransferClick?: (playerId: number) => void;
  showTransferButton?: boolean;
}

export const PlayerCard: React.FC<PlayerCardProps> = ({
  player,
  onTransferClick,
  showTransferButton = true
}) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const handleTransferClick = useCallback(async () => {
    if (!onTransferClick) return;
    
    setIsLoading(true);
    setError(null);
    
    try {
      await onTransferClick(player.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Transfer failed');
    } finally {
      setIsLoading(false);
    }
  }, [player.id, onTransferClick]);
  
  if (error) {
    return <ErrorBoundary error={error} onRetry={() => setError(null)} />;
  }
  
  return (
    <div className="player-card" data-testid={`player-card-${player.id}`}>
      {/* Component implementation */}
    </div>
  );
};

// Export with display name for debugging
PlayerCard.displayName = 'PlayerCard';
```

**API Client Standards**
```typescript
// Good: Typed API client with error handling
export class FPLApiClient {
  private readonly baseUrl: string;
  private readonly timeout: number;
  
  constructor(baseUrl: string, timeout = 5000) {
    this.baseUrl = baseUrl;
    this.timeout = timeout;
  }
  
  async getPlayerStats(playerId: number): Promise<PlayerStats> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);
    
    try {
      const response = await fetch(`${this.baseUrl}/players/${playerId}/stats`, {
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':