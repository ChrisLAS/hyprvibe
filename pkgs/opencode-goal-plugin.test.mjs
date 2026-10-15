import assert from "node:assert/strict"
import { appendFileSync, copyFileSync, mkdtempSync, rmSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import { pathToFileURL } from "node:url"
import test from "node:test"

const workDir = process.cwd()
const bundle = join(workDir, "dist", "server.js")
const testBundle = join(workDir, "dist", "server.test.mjs")
const stateDir = mkdtempSync(join(tmpdir(), "opencode-goal-state-"))
process.env.OPENCODE_GOAL_STATE_PATH = join(stateDir, "goals.json")
copyFileSync(bundle, testBundle)
appendFileSync(testBundle, `\nexport { accountUsage as testAccountUsage, createGoal as testCreateGoal, getGoal as testGetGoal, setGoalStatus as testSetGoalStatus, tokensFromRecord as testTokensFromRecord };\n`)
const plugin = await import(pathToFileURL(testBundle).href)
let nextSession = 0
const newGoal = (tokenBudget) => {
  const sessionID = `goal-budget-regression-${++nextSession}`
  return plugin.testCreateGoal(sessionID, "Exercise goal token accounting", { tokenBudget }).then(() => sessionID)
}

test("usage and budget both use raw token counts", async () => {
  assert.equal(plugin.testTokensFromRecord({ input: 12_000, output: 500, reasoning: 250, cache: { read: 7_000, write: 100 } }), 19_850)
  const sessionID = await newGoal(19_850)
  const goal = await plugin.testAccountUsage(sessionID, 19_850, { cumulative: true, source: "test", initialBaseline: 0 })
  assert.equal(goal.tokensUsed, goal.tokenBudget)
  assert.equal(goal.status, "budgetLimited")
})

test("cumulative usage increments by turn and persists", async () => {
  const sessionID = await newGoal(1_000)
  await plugin.testAccountUsage(sessionID, 100, { cumulative: true, source: "test", initialBaseline: 0 })
  const firstRead = await plugin.testGetGoal(sessionID)
  assert.equal(firstRead.tokensUsed, 100)
  await plugin.testAccountUsage(sessionID, 160, { cumulative: true, source: "test", initialBaseline: 0 })
  const secondRead = await plugin.testGetGoal(sessionID)
  assert.equal(secondRead.tokensUsed, 160)
})

test("resume does not count a stale cumulative observation twice", async () => {
  const sessionID = await newGoal(1_000)
  await plugin.testAccountUsage(sessionID, 40, { cumulative: true, source: "test", initialBaseline: 0 })
  await plugin.testSetGoalStatus(sessionID, "paused")
  const resumed = await plugin.testSetGoalStatus(sessionID, "active")
  assert.equal(resumed.status, "active")
  assert.equal(resumed.tokensUsed, 40)
  const replayed = await plugin.testAccountUsage(sessionID, 40, { cumulative: true, source: "test", initialBaseline: 0 })
  assert.equal(replayed.tokensUsed, 40)
  const incremented = await plugin.testAccountUsage(sessionID, 65, { cumulative: true, source: "test", initialBaseline: 0 })
  assert.equal(incremented.tokensUsed, 65)
  assert.equal(incremented.status, "active")
})

test("resume leaves exhausted goals limited and under-budget goals active", async () => {
  const exhaustedID = await newGoal(100)
  await plugin.testAccountUsage(exhaustedID, 100, { cumulative: true, source: "test", initialBaseline: 0 })
  const exhaustedResume = await plugin.testSetGoalStatus(exhaustedID, "active")
  assert.equal(exhaustedResume.status, "budgetLimited")
  assert.equal(exhaustedResume.tokensUsed, 100)

  const unexhaustedID = await newGoal(100)
  await plugin.testAccountUsage(unexhaustedID, 40, { cumulative: true, source: "test", initialBaseline: 0 })
  await plugin.testSetGoalStatus(unexhaustedID, "paused")
  const unexhaustedResume = await plugin.testSetGoalStatus(unexhaustedID, "active")
  assert.equal(unexhaustedResume.status, "active")
  assert.equal(unexhaustedResume.tokensUsed, 40)
})

test.after(() => {
  rmSync(testBundle, { force: true })
  rmSync(stateDir, { recursive: true, force: true })
})
