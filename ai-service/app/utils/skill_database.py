"""
Skill Database — Comprehensive dictionary of known technical skills.

Organized by category for maintainability.
To add new skills, simply append to the relevant list below.

The module also exports pre-computed data structures:
  ALL_SKILLS    — flat set for O(1) membership checks
  SORTED_SKILLS — sorted longest-first for greedy matching
  ALIAS_MAP     — canonical form mapping for deduplication
"""

# ═══════════════════════════════════════════════════════════
# CATEGORIZED SKILL DICTIONARY
# ═══════════════════════════════════════════════════════════

SKILL_DATABASE: dict[str, list[str]] = {
    "programming_languages": [
        "python", "javascript", "typescript", "java", "c", "c++", "c#",
        "go", "golang", "rust", "ruby", "php", "swift", "kotlin", "scala",
        "r", "matlab", "perl", "lua", "dart", "objective-c", "haskell",
        "elixir", "clojure", "assembly", "fortran", "cobol", "vba",
        "shell", "bash", "powershell", "sql", "plsql", "groovy",
    ],
    "web_frontend": [
        "html", "html5", "css", "css3", "sass", "scss", "less",
        "tailwindcss", "tailwind css", "bootstrap", "material ui",
        "react", "reactjs", "react.js", "react native",
        "angular", "angularjs", "angular.js",
        "vue", "vuejs", "vue.js", "nuxt", "nuxtjs", "nuxt.js",
        "next.js", "nextjs", "svelte", "sveltekit",
        "webpack", "vite", "babel", "jquery", "redux", "zustand",
        "graphql", "rest api", "restful api",
    ],
    "web_backend": [
        "node.js", "nodejs", "express", "expressjs", "express.js",
        "fastapi", "flask", "django", "spring boot", "spring",
        "asp.net", ".net", "dotnet", "rails", "ruby on rails",
        "laravel", "symfony", "gin", "fiber", "echo", "fastify",
        "nest.js", "nestjs", "koa", "hapi",
    ],
    "mobile": [
        "flutter", "react native", "android", "ios", "swiftui",
        "kotlin multiplatform", "xamarin", "ionic", "cordova",
        "jetpack compose", "uikit",
    ],
    "databases": [
        "mongodb", "mongoose", "mysql", "postgresql", "postgres",
        "sqlite", "redis", "elasticsearch", "cassandra", "dynamodb",
        "firebase", "firestore", "supabase", "neo4j", "couchdb",
        "mariadb", "oracle db", "mssql", "sql server",
    ],
    "devops_cloud": [
        "docker", "kubernetes", "k8s", "aws", "amazon web services",
        "azure", "google cloud", "gcp", "heroku", "vercel", "netlify",
        "render", "digitalocean", "terraform", "ansible", "jenkins",
        "ci/cd", "github actions", "gitlab ci", "circleci",
        "nginx", "apache", "linux", "ubuntu",
    ],
    "data_science_ai": [
        "machine learning", "deep learning", "artificial intelligence",
        "natural language processing", "nlp", "computer vision",
        "tensorflow", "pytorch", "keras", "scikit-learn", "sklearn",
        "pandas", "numpy", "scipy", "matplotlib", "seaborn",
        "opencv", "hugging face", "transformers", "bert", "gpt",
        "langchain", "llm", "data analysis", "data visualization",
        "data mining", "statistics", "regression", "classification",
        "clustering", "neural network", "cnn", "rnn", "lstm",
        "random forest", "xgboost", "lightgbm",
        "tableau", "power bi", "jupyter", "spark", "hadoop",
        "airflow", "kafka", "etl",
    ],
    "tools_and_platforms": [
        "git", "github", "gitlab", "bitbucket",
        "jira", "confluence", "trello", "asana", "notion",
        "figma", "adobe xd", "sketch", "photoshop", "illustrator",
        "postman", "swagger", "insomnia",
        "vs code", "visual studio", "intellij", "android studio", "xcode",
    ],
    "concepts": [
        "agile", "scrum", "kanban", "devops", "microservices",
        "api design", "system design", "data structures", "algorithms",
        "object oriented programming", "oop", "functional programming",
        "test driven development", "tdd", "unit testing",
        "design patterns", "solid principles",
        "responsive design", "pwa", "progressive web app",
        "websocket", "socket.io", "grpc", "rabbitmq",
        "oauth", "jwt", "authentication", "authorization",
        "blockchain", "web3", "solidity", "smart contracts",
    ],
}


# ═══════════════════════════════════════════════════════════
# PRECOMPUTED LOOKUP STRUCTURES
# ═══════════════════════════════════════════════════════════

# Flat set of every skill for O(1) membership tests
ALL_SKILLS: set[str] = set()
for _category_skills in SKILL_DATABASE.values():
    ALL_SKILLS.update(_category_skills)

# Sorted longest-first so multi-word matches take priority
# e.g. "react native" is matched before "react"
SORTED_SKILLS: list[str] = sorted(ALL_SKILLS, key=len, reverse=True)


# ═══════════════════════════════════════════════════════════
# ALIAS MAP  —  variant → canonical form
# ═══════════════════════════════════════════════════════════

ALIAS_MAP: dict[str, str] = {
    "reactjs": "react",
    "react.js": "react",
    "angularjs": "angular",
    "angular.js": "angular",
    "vuejs": "vue",
    "vue.js": "vue",
    "nodejs": "node.js",
    "expressjs": "express",
    "express.js": "express",
    "nextjs": "next.js",
    "nuxtjs": "nuxt",
    "nuxt.js": "nuxt",
    "nestjs": "nest.js",
    "golang": "go",
    "sklearn": "scikit-learn",
    "postgres": "postgresql",
    "k8s": "kubernetes",
    "amazon web services": "aws",
    "dotnet": ".net",
}
