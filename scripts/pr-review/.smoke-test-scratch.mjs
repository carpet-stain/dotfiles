// Throwaway file to smoke-test pr-code-review.yml's comment-posting path.
// Deliberately broken — never merge. Deleted after the test PR is closed.
import { execSync } from "node:child_process";

export function greet(userInput) {
  return execSync(`echo Hello, ${userInput}`).toString();
}
