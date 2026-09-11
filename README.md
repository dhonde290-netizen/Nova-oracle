# Weekend Deployment Challenge: Nova Oracle

## What Your App Does
**Nova Oracle** is a sleek, minimalist AI assistant that stands out from standard chatbots by adopting a "cyberpunk/glassmorphism" aesthetic. Rather than feeling like a generic interface, the Oracle provides a profound, focused user experience. 

It starts with a simple "Seek the wisdom of the cloud" prompt. Once you interact, the interface dynamically responds: the main header gracefully minimizes to the top corner, making way for a continuous, scrollable conversational thread. The Oracle writes its responses using a custom, Markdown-aware typewriter effect, and the interface is smart enough to auto-scroll with the text—unless you manually scroll up to read past wisdom, at which point it respects your interruption!

## How You Built It
The development process evolved from a simple one-off query tool into a fully persistent, robust chatbot interface, all while maintaining a 100% serverless architecture. I knew I wanted to use Amazon Bedrock to tap into the new Nova models, but I wanted to avoid the complexity of managing servers or containers.

**Key Decisions & Challenges:**
- **Frontend Design & UX:** I opted for a custom HTML/CSS/JS frontend to achieve the aesthetic rather than using an out-of-the-box UI component library. A major challenge was building a custom Markdown parser (`marked.js`) into a custom "typewriter" animation so that bold text, code blocks, and bullet points render cleanly as they type out. I also implemented "smart auto-scroll" logic that detects if the user has manually scrolled up to pause the auto-scroll.
- **Backend Architecture:** I needed a way for the static frontend to securely talk to Amazon Bedrock. Instead of setting up a complex API Gateway + Lambda combination, I utilized **Lambda Function URLs**. This newer feature allowed me to expose my Lambda function directly via an HTTP endpoint, vastly simplifying the deployment.
- **CORS Configuration:** The biggest hurdle was ensuring the S3-hosted frontend could make POST requests to the Lambda Function URL. Because AWS manages CORS for Function URLs natively, I learned that manually injecting `Access-Control-Allow-Origin` headers in my Python code actually caused conflicts (`Failed to fetch`), so stripping those out and letting AWS handle the CORS policy was the solution.

## AWS Services Used / Architecture Overview
The architecture is completely serverless:
1. **Amazon S3**: Hosts the static frontend files (HTML, CSS, JS).
2. **AWS Lambda (with Function URL)**: Acts as the secure backend middleman. It receives the HTTP POST request from the frontend and executes the Python `boto3` code.
3. **Amazon Bedrock**: The brain of the operation. The Lambda function invokes the `amazon.nova-micro-v1:0` model via the Converse API to generate the AI responses.
4. **AWS IAM**: Manages precise permissions, ensuring the Lambda function execution role has the right to invoke Bedrock.

*Architecture Flow:* 
`User Browser -> S3 Static Website -> HTTP POST -> Lambda Function URL -> Amazon Bedrock`

## What You Learned
This challenge reinforced the power of serverless building and rapid iteration. Specifically, I learned:
- **Lambda Function URLs** are an incredible time-saver for single-purpose APIs where a full API Gateway isn't necessary.
- **Amazon Bedrock's Converse API** makes it remarkably easy to integrate foundational models. The standardized message format (`role`, `content`) means I can easily maintain conversation history by passing arrays of messages.
- **Managing browser state without frameworks** (like React) forces you to really understand the DOM. Building the custom HTML-aware typewriter effect and managing scroll state manually was a great exercise in core JavaScript.

## Link to App or Repo
**Live App:** [Nova Oracle Live Demo](http://nova-oracle-website-dcrsol.s3-website.ap-south-1.amazonaws.com)  
**Source Code:** [GitHub Repository](https://github.com/dhonde290-netizen/Nova-oracle)
