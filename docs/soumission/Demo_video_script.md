# FlowPulse – Demo video script (7 minutes)

Structure requested by the organisers: hardware and software setup, main functions, expected outcome of each scenario, real outcome from the AI solution. Screen recording of <https://flowpulse2.duckdns.org>, 1920 × 1080, voice-over in English.

| Time | Screen | Voice-over |
| --- | --- | --- |
| 0:00–0:30 | Public home page | Yaoundé plans its buses on outdated data and reacts to congestion once it has formed. FlowPulse gives the city's mobility managers AI agents that anticipate saturation, propose actions, and check every action against the law. |
| 0:30–1:15 | Architecture diagram (README) | **Setup.** One CPU-only server with Docker Compose: React interface, Spring Boot for security, roles and audit, a FastAPI AI service, PostgreSQL, ChromaDB for the knowledge base, and Ollama running the language model locally. No data leaves the server. Mobility profiles come from the real D4D-Senegal dataset, transposed onto Yaoundé's 7 communes; the bus fleet is demonstration data. |
| 1:15–2:15 | Dashboard (log in as urban manager) | **Observe and forecast.** Each commune has a tension index out of 100: dense from 75, saturated from 85. LightGBM forecasts the next 1 and 2 hours. Click Yaoundé II: the curve shows the observed day and the forecast. |
| 2:15–3:15 | Alerts, then Fleet | **Propose and verify.** Run a surveillance: 5 alerts, each with a contingency plan. On the Fleet screen, the reinforcements proposed by the Optimizer carry the Policy agent's verdict and the cited texts. Apply one; reject another with a reason, "two buses in maintenance". |
| 3:15–4:30 | Simulation | **Scenario A, expected:** closing Boulevard du 20 Mai from 7 to 10 should shift traffic to neighbouring communes. **Real outcome:** 2 → 3 saturated communes, Yaoundé II +12 points, travel time +3 %, measures verified with citations. **Scenario B:** a 40,000-spectator match at Ahmadou Ahidjo stadium raises Yaoundé V from 83 to 91. Show the verdict and open the reasoning: the human sees the passages used and keeps the decision. |
| 4:30–5:30 | AI supervisor | Ask "Which zone is the most saturated right now?" then "Who is competent to organise urban transport?". The supervisor chooses its tools, answers with sources, and "See the reasoning" lists every step and passage. |
| 5:30–6:20 | Knowledge base, Regulatory gaps | **Knowledge base:** 21 texts inventoried, 10 indexed, split by article. **Gaps:** 7 documented gaps, for example no text designates who may authorise an operator to share aggregated mobility data with a city; each gap is paired with a global example (EU Data Act, ISO/IEC 20889, EU AI Act). |
| 6:20–6:50 | Audit log | Every human decision is logged with its author, time and reason, and can be exported as CSV. |
| 6:50–7:00 | Home page | FlowPulse: anticipate, propose, verify, and let people decide. Mboa Labs, Yaoundé. |

Recording tips: use the light theme, close the welcome box, zoom the browser to 110 %, and pre-run the two simulations so that their results open instantly from the history.
