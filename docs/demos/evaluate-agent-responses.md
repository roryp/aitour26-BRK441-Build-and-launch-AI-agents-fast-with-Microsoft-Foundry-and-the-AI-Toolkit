# Demo Instructions

**Instructions**: View the updates made to the agent instructions.

**Script**: Back here in the Agent Builder, you  may notice that the instructions look a little different. The reason being is that when you're going to do evaluations, you need to have at least 1 variable defined in your instructions. As you can see, the variable Serena's chosen is **product**. That makes the **product** value dynamic so that whenever I run an evaluation, it's going to pass in the value for **product** in it's place and it'll become part of the instructions for that iteration of the evaluation run.

---

**Instructions**: Scroll down to the **Variables** section to view the list of variables.

**Script**: If I scroll down to the **Variables** section, I can see that it includes the variable **product**.

---

**Instructions**: Switch to the **Evaluation** tab. Select the **Generate Data** button.

**Script**: Switching over to the Evaluation tab, the first thing that I want to call out is the Generate Data feature. The feature enable us to generate data in the form of user prompts and values for the variable. So, why is this helpful? Well, you may not always have evaluation data readily available, especially if you’re just at the prototyping phase. When you use the Generate Data feature, the Toolkit provides a prompt that’ll be used by the LLM to generate variable values with respect to the context of the variable. It takes the system prompt into consideration as context to help guide which sort of variable values to generate.​ Alternatively, you could upload your own dataset or manually add rows of data.

---

​**Instructions**: Switch to the v3-manual-eval agent version. Review the data and responses in the table.

**Script**:  I have the dataset here that Serena used and I've run each row to get Cora's response.

---

​**Instructions**: Select thumb up or thumb down for each row.

**Script**: ​I'll now go through each row and manually assess whether Cora's output should receive a thumb up or down. Now that I’ve done the manual evaluation, I can export the results as a .JSONL file to save as a reference for future iterations of Cora. I could also save this entire version of Cora and come back to it later to compare evaluation results against a different version of Cora’s configuration.​ So, that covers manual evaluation which keeps a human in the loop for evaluating responses.​

---

**Instructions**: Switch to the v4-automated-evaluation and go to the Evaluation tab. Review the results from the evaluation run.

**Script**: As mentioned, I could also automate this process with an automated evaluation that uses a language model (or AI) as the judge. We can take a look at the results that Serena received when she did an automated evaluation for her initial dataset.​
