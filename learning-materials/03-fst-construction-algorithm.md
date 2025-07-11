# FST Construction & Querying: Step-by-Step Deep Dive

## 🔨 **Step-by-Step FST Construction Algorithm**

### **Input Data**
```java
// Words with their term IDs (sorted lexicographically - CRITICAL!)
String[] words = {"car", "card", "care", "cat", "cats"};
int[] termIds = {10, 11, 12, 20, 21};
```

### **Phase 1: Trie Construction (Similar to Traditional)**

```java
// Step 1: Build basic trie structure
class TrieNode {
    Map<Character, TrieNode> children = new HashMap<>();
    boolean isFinal = false;
    int termId = -1;
}

TrieNode root = new TrieNode();

// Insert each word
for (int i = 0; i < words.length; i++) {
    TrieNode current = root;
    for (char c : words[i].toCharArray()) {
        current.children.putIfAbsent(c, new TrieNode());
        current = current.children.get(c);
    }
    current.isFinal = true;
    current.termId = termIds[i];
}
```

**After Phase 1 - Basic Trie:**
```
      root(0)
         |
         c
         |
         a
        / \
       r   t
      /|\   \
     ∅ d ∅   ∅
    10 | 12  20
       ∅     |
       11    s
             |
             ∅
             21
```

### **Phase 2: Suffix Identification (The Magic!)**

```java
// Step 2: Find identical subtrees (suffixes)
Map<String, Integer> suffixToState = new HashMap<>();
Map<TrieNode, Integer> nodeToState = new HashMap<>();
int stateCounter = 0;

// Post-order traversal to identify shared suffixes
public int identifySuffixes(TrieNode node) {
    if (node == null) return -1;
    
    // Process children first (post-order)
    for (TrieNode child : node.children.values()) {
        identifySuffixes(child);
    }
    
    // Create signature for this subtree
    String signature = createSignature(node);
    
    if (suffixToState.containsKey(signature)) {
        // This subtree already exists - reuse the state!
        int existingState = suffixToState.get(signature);
        nodeToState.put(node, existingState);
        return existingState;
    } else {
        // New unique subtree - assign new state
        int newState = stateCounter++;
        suffixToState.put(signature, newState);
        nodeToState.put(node, newState);
        return newState;
    }
}

private String createSignature(TrieNode node) {
    StringBuilder sig = new StringBuilder();
    if (node.isFinal) {
        sig.append("FINAL:").append(node.termId).append(";");
    }
    
    // Sort children for consistent signature
    TreeMap<Character, Integer> sortedChildren = new TreeMap<>();
    for (Map.Entry<Character, TrieNode> entry : node.children.entrySet()) {
        sortedChildren.put(entry.getKey(), nodeToState.get(entry.getValue()));
    }
    
    for (Map.Entry<Character, Integer> entry : sortedChildren.entrySet()) {
        sig.append(entry.getKey()).append("->").append(entry.getValue()).append(";");
    }
    
    return sig.toString();
}
```

**After Phase 2 - Suffix Sharing:**
```
Signatures:
- "FINAL:21;" → State 5 (cats ending)
- "FINAL:20;s->5;" → State 4 (cat with s option)
- "FINAL:12;" → State 3 (care ending)
- "FINAL:11;" → State 2 (card ending)  
- "FINAL:10;d->2;e->3;" → State 1 (car with d/e options)
- "r->1;t->4;" → State 0 (root ca with r/t options)
```

### **Phase 3: FST State Transition Table**

```java
// Step 3: Build final FST transition table
class FST {
    Map<Integer, Map<Character, Transition>> states = new HashMap<>();
    
    static class Transition {
        int targetState;
        int output; // term_id if final state, -1 otherwise
        
        Transition(int targetState, int output) {
            this.targetState = targetState;
            this.output = output;
        }
    }
}

// Build transition table
FST fst = new FST();
for (TrieNode node : nodeToState.keySet()) {
    int currentState = nodeToState.get(node);
    Map<Character, Transition> transitions = new HashMap<>();
    
    for (Map.Entry<Character, TrieNode> entry : node.children.entrySet()) {
        char c = entry.getKey();
        TrieNode child = entry.getValue();
        int targetState = nodeToState.get(child);
        int output = child.isFinal ? child.termId : -1;
        
        transitions.put(c, new Transition(targetState, output));
    }
    
    fst.states.put(currentState, transitions);
}
```

**Final FST Structure:**
```
State 0: {c -> State 1}
State 1: {a -> State 2}  
State 2: {r -> State 3, t -> State 4}
State 3: {FINAL(10), d -> State 5, e -> State 6}
State 4: {FINAL(20), s -> State 7}
State 5: {FINAL(11)}
State 6: {FINAL(12)}
State 7: {FINAL(21)}
```

## 🔍 **Step-by-Step Query Processing**

### **Query: "cat"**

```java
public int queryFST(String term) {
    int currentState = 0; // Start at root
    
    for (char c : term.toCharArray()) {
        Map<Character, Transition> transitions = fst.states.get(currentState);
        
        if (!transitions.containsKey(c)) {
            return -1; // Term not found
        }
        
        Transition transition = transitions.get(c);
        currentState = transition.targetState;
        
        System.out.println("Character '" + c + "': State " + 
                          currentState + " -> " + transition.targetState);
    }
    
    // Check if current state is final
    // (In real FST, final states store outputs)
    return getCurrentStateOutput(currentState);
}

// Query execution trace:
queryFST("cat");
// Character 'c': State 0 -> 1
// Character 'a': State 1 -> 2  
// Character 't': State 2 -> 4
// State 4 is final with output 20
// Result: term_id = 20
```

### **Query: "car*" (Prefix Query)**

```java
public List<Integer> prefixQuery(String prefix) {
    int currentState = 0;
    
    // Navigate to prefix end
    for (char c : prefix.toCharArray()) {
        Map<Character, Transition> transitions = fst.states.get(currentState);
        if (!transitions.containsKey(c)) {
            return Collections.emptyList();
        }
        currentState = transitions.get(c).targetState;
    }
    
    // Collect all reachable final states
    List<Integer> results = new ArrayList<>();
    collectAllFinalStates(currentState, results);
    return results;
}

// Query execution:
prefixQuery("car");
// Navigate: c(0->1) -> a(1->2) -> r(2->3)
// From state 3, collect all final states:
// - State 3 itself: term_id 10 ("car")  
// - State 5 via 'd': term_id 11 ("card")
// - State 6 via 'e': term_id 12 ("care")
// Result: [10, 11, 12]
```

## ⚡ **Performance Comparison: FST vs Trie**

### **Construction Time Complexity**

```java
// Trie Construction
for (String word : words) {           // O(n)
    for (char c : word.toCharArray()) { // O(k)
        // Insert character
    }
}
// Total: O(n * k) where n=words, k=avg length

// FST Construction  
buildTrie();                    // O(n * k)
identifySuffixes();            // O(nodes * log nodes) 
buildTransitionTable();        // O(nodes)
// Total: O(n * k + nodes * log nodes)
// BUT: FST construction is done offline during indexing
```

### **Query Time Complexity**

```java
// Both Trie and FST: O(k) where k = query length
// Same algorithmic complexity!

// Memory Access Patterns:
// Trie: Random pointer following (cache misses)
// FST: Sequential state transitions (cache friendly)
```

### **Memory Usage Breakdown**

```java
// Example: 100K English words

Trie Memory:
- Nodes: 500K nodes × 32 bytes = 16MB
- HashMap overhead: 500K × 24 bytes = 12MB  
- Total: ~28MB

FST Memory:
- States: 50K states × 8 bytes = 400KB
- Transitions: 200K transitions × 4 bytes = 800KB
- Total: ~1.2MB

Compression Ratio: 28MB / 1.2MB = 23:1 !!!
```

## 🎯 **Key Algorithmic Differences**

| **Operation** | **Trie** | **FST** |
|---------------|----------|---------|
| **Construction** | O(n×k) online | O(n×k + nodes×log nodes) offline |
| **Lookup** | O(k) pointer chase | O(k) state transition |
| **Prefix Query** | O(k + results) DFS | O(k + results) state enumeration |
| **Memory** | O(nodes) scattered | O(states) compact |
| **Updates** | ✅ Mutable | ❌ Immutable |
| **Cache Performance** | ❌ Poor locality | ✅ Excellent locality |

## 🚨 **Production Implementation Notes**

```java
// Real FST optimizations in Lucene:
1. Variable-length integer encoding for states
2. Arc compression for linear chains  
3. Minimal perfect hashing for transition lookup
4. Memory-mapped file storage for persistence
5. Lazy loading of transition tables

// Construction is expensive:
FSTBuilder builder = new FSTBuilder(); // Sorts input!
for (String term : sortedTerms) {
    builder.add(term, termId);         // Must be sorted!
}
FST fst = builder.finish();           // Expensive step
```

---

**🎯 Key Takeaway:** FST construction is **significantly more complex** than Trie, but the **runtime benefits are massive**. The suffix sharing algorithm turns FST construction into a **one-time expensive operation** that pays dividends through **orders of magnitude memory savings** and **better cache performance**.

This is why Lucene builds FSTs during **segment creation** (offline) rather than during queries (online). The complexity pays off at scale! 🚀

Ready to see how Elasticsearch, Solr, and OpenSearch expose these optimized data structures through their APIs?
